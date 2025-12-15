import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final double totalAmount;
  final String status; // 'pending', 'paid', 'shipping', 'completed'
  final DateTime orderDate;
  final List<CartItemModel> items;
  final String shippingAddress;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.items,
    required this.shippingAddress,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
      'items':
          items
              .map((x) => x.toMap())
              .toList(), // You might need to add toMap() to CartItemModel too!
      'shippingAddress': shippingAddress,
    };
  }
}
