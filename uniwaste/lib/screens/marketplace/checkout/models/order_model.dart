import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

// Model representing an order
class OrderModel {
  final String orderId;
  final String userId;
  final String userName;
  final double totalAmount;
  final String status;
  final DateTime orderDate;
  final List<CartItemModel> items;
  final String shippingAddress;
  final String method;
  final String merchantId;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.items,
    required this.shippingAddress,
    required this.method,
    required this.merchantId,
  });

  // Helper to convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
      'items': items.map((x) => x.toMap()).toList(),
      'shippingAddress': shippingAddress,
      'method': method,
      // ✅ SAVE TO DB
      'merchantId': merchantId,
    };
  }
}
