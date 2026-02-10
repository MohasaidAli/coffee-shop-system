
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      token: json['token'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final int stock;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['imageUrl'] ?? '',
      stock: json['stock'],
      description: json['description'] ?? '',
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'coffee_id': product.id,
      'quantity': quantity,
      'price': product.price,
    };
  }
}
