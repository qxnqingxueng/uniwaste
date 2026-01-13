import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniwaste/screens/marketplace/checkout/models/order_model.dart';

// Repository to handle order-related operations
class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to save the order to Firebase
  Future<void> createOrder(OrderModel order) async {
    try {
      // This saves the order under a collection called 'orders'
      await _firestore
          .collection('orders')
          .doc(order.orderId)
          .set(order.toMap());

      print("Order ${order.orderId} saved successfully!");
    } catch (e) {
      print("Error saving order: $e");
      throw Exception("Failed to create order");
    }
  }
}
