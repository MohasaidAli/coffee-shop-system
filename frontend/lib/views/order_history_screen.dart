import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';

class OrderHistoryScreen extends StatelessWidget {
  final OrderController orderController = Get.put(OrderController());

  OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    orderController.fetchMyOrders();

    return Scaffold(
      appBar: AppBar(title: Text('My Orders')),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        if (orderController.orders.isEmpty) {
          return Center(child: Text('No orders found'));
        }
        return ListView.builder(
          itemCount: orderController.orders.length,
          itemBuilder: (ctx, i) {
            final order = orderController.orders[i];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: Icon(Icons.receipt_long, color: Colors.brown),
                title: Text('Order #${order['id']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${order['order_date'].toString().substring(0, 10)}',
                    ),
                    if (order['location'] != null)
                      Text('Location: ${order['location']}'),
                    if (order['contact'] != null)
                      Text('Contact: ${order['contact']}'),
                    if (order['note'] != null &&
                        order['note'].toString().isNotEmpty)
                      Text(
                        'Note: ${order['note']}',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    if (order['cancel_reason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Cancel Reason: ${order['cancel_reason']}',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _getStatusColor(order['status']),
                            ),
                          ),
                          child: Text(
                            order['status'] ?? 'Pending',
                            style: TextStyle(
                              color: _getStatusColor(order['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (order['status'] == 'Pending')
                          TextButton.icon(
                            onPressed: () => _showCancelDialog(order['id']),
                            icon: Icon(
                              Icons.cancel,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        if (order['status'] == 'Canceled' &&
                            order['canceled_by'] == 'customer')
                          TextButton.icon(
                            onPressed: () =>
                                orderController.reactivateOrder(order['id']),
                            icon: Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.green,
                            ),
                            label: Text(
                              'Reactivate',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Text(
                  '\$${double.parse(order['total_amount'].toString()).toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Preparing':
        return Colors.orange;
      case 'Delivered':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showCancelDialog(int orderId) {
    final TextEditingController reasonController = TextEditingController();
    Get.defaultDialog(
      title: 'Cancel Order',
      content: TextField(
        controller: reasonController,
        decoration: InputDecoration(labelText: 'Reason for cancellation'),
        maxLines: 2,
      ),
      textConfirm: 'Confirm Cancel',
      textCancel: 'Exit',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (reasonController.text.isEmpty) {
          Get.snackbar('Error', 'Please provide a reason');
          return;
        }
        orderController.cancelOrder(orderId, reasonController.text, 'customer');
        Get.back();
      },
    );
  }
}
