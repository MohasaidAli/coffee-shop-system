import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_controller.dart';

class OrderController extends GetxController {
  var orders = [].obs;
  var isLoading = false.obs;

  Future<void> fetchMyOrders() async {
    final AuthController authController = Get.find<AuthController>();
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse(
          '${Constants.baseUrl}/orders/${authController.user.value!.id}',
        ),
      );

      if (response.statusCode == 200) {
        orders.value = jsonDecode(response.body);
      } else {
        Get.snackbar('Error', 'Failed to fetch orders');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading(false);
    }
  }

  // Admin: Fetch all orders
  var allOrders = [].obs;
  var totalRevenue = 0.0.obs;
  var potentialRevenue = 0.0.obs;

  Future<void> fetchAllOrders() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/orders/admin/all'),
      );
      if (response.statusCode == 200) {
        allOrders.value = jsonDecode(response.body);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch all orders');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchRevenueStats() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/orders/admin/revenue'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        totalRevenue.value =
            double.tryParse(data['totalRevenue']?.toString() ?? '0') ?? 0.0;
        potentialRevenue.value =
            double.tryParse(data['potentialRevenue']?.toString() ?? '0') ?? 0.0;
      }
    } catch (e) {
      print('Error fetching revenue: $e');
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('${Constants.baseUrl}/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Order status updated to $status');
        fetchAllOrders(); // Refresh orders
        fetchRevenueStats(); // Refresh revenue
      } else {
        Get.snackbar('Error', 'Failed to update status');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    }
  }

  Future<void> cancelOrder(
    int orderId,
    String reason,
    String canceledBy,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('${Constants.baseUrl}/orders/$orderId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason, 'canceledBy': canceledBy}),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Order canceled successfully');
        fetchMyOrders(); // Refresh user orders
        fetchAllOrders(); // Refresh admin orders
        fetchRevenueStats(); // Refresh revenue
      } else {
        Get.snackbar('Error', 'Failed to cancel order');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    }
  }

  Future<void> reactivateOrder(int orderId) async {
    try {
      final response = await http.patch(
        Uri.parse('${Constants.baseUrl}/orders/$orderId/reactivate'),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Order reactivated to Pending');
        fetchMyOrders();
        fetchAllOrders();
        fetchRevenueStats();
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar('Error', data['message'] ?? 'Failed to reactivate order');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    }
  }
}
