import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import CartBloc
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';

import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';
import 'package:uniwaste/screens/marketplace/checkout/edit_address_screen.dart';
import 'package:uniwaste/screens/marketplace/checkout/models/delivery_info.dart';
import 'package:uniwaste/services/payment_service.dart';
import 'package:uniwaste/screens/marketplace/order_tracking/order_status_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryInfo _deliveryInfo = DeliveryInfo();
  bool _isProcessing = false;
  bool isDelivery = true;

  final Color bgCream = const Color(0xFFF1F3E0);
  final Color sageGreen = const Color(0xFFD2DCB6);
  final Color accentGreen = const Color(0xFFA1BC98);
  final Color darkGreen = const Color(0xFF778873);

  Future<void> _handlePayment(List<CartItemModel> items, double amount) async {
    setState(() => _isProcessing = true);

    // 1. Process Payment
    final success = await PaymentService.instance.makePayment(context, amount);

    if (success) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final orderId = DateTime.now().millisecondsSinceEpoch.toString();

        // Extract Merchant ID safely
        final String merchantId =
            items.isNotEmpty ? (items.first.merchantId ?? '') : '';

        if (merchantId.isEmpty) {
          print("❌ ERROR: Merchant ID is empty! Order will not sync.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: System cannot identify the merchant."),
            ),
          );
          setState(() => _isProcessing = false);
          return;
        }

        try {
          // 2. Update Inventory (Quantity & Availability)
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            for (var item in items) {
              // Point to the specific merchant's item collection
              DocumentReference merchantItemRef = FirebaseFirestore.instance
                  .collection('merchants')
                  .doc(merchantId)
                  .collection('items')
                  .doc(item.id);

              DocumentSnapshot snapshot = await transaction.get(
                merchantItemRef,
              );

              if (snapshot.exists) {
                var currentQty = snapshot.get('quantity');
                int qtyInt =
                    (currentQty is int)
                        ? currentQty
                        : int.tryParse(currentQty.toString()) ?? 0;

                int newQty = qtyInt - item.quantity;
                if (newQty < 0) newQty = 0;

                // ✅ FIX: Update both quantity AND availability
                transaction.update(merchantItemRef, {
                  'quantity': newQty,
                  'isAvailable':
                      newQty >
                      0, // If 0, it becomes false and disappears from UI
                });

                print(
                  "✅ Updated Item: ${item.name} | Qty: $newQty | Available: ${newQty > 0}",
                );
              }
            }
          });

          // 3. Prepare Order Data
          final orderData = {
            'orderId': orderId,
            'userId': user.uid,
            'userName': user.displayName ?? "Student",
            'userEmail': user.email ?? "",
            'totalAmount': amount,
            'status': 'pending', // Merchant sees this as new
            'orderDate': FieldValue.serverTimestamp(),
            'merchantId': merchantId,
            'shippingAddress':
                isDelivery
                    ? "${_deliveryInfo.name}, ${_deliveryInfo.address}"
                    : "Self Pick-Up",
            'method': isDelivery ? 'Delivery' : 'Pick Up',
            'items':
                items
                    .map(
                      (i) => {
                        'id': i.id,
                        'name': i.name,
                        'price': i.price,
                        'quantity': i.quantity,
                        'imagePath': i.imagePath,
                      },
                    )
                    .toList(),
          };

          // 4. Double Write Strategy (Sync Fix)

          // Write A: Global Orders (Student)
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .set(orderData);

          // Write B: Merchant Orders (Merchant)
          await FirebaseFirestore.instance
              .collection('merchants')
              .doc(merchantId)
              .collection('orders')
              .doc(orderId)
              .set(orderData);

          if (mounted) {
            context.read<CartBloc>().add(ClearCart());
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => OrderStatusScreen(orderId: orderId),
              ),
            );
          }
        } catch (e) {
          print("❌ Order Creation Failed: $e");
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Order failed: $e")));
          }
        }
      }
    } else {
      print("Payment flow failed or cancelled.");
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgCream,
        elevation: 0,
        iconTheme: IconThemeData(color: darkGreen),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty) {
            return const Center(child: Text("No items"));
          }

          final checkoutItems = state.items.where((i) => i.isSelected).toList();
          final subtotal = checkoutItems.fold(
            0.0,
            (sum, i) => sum + (i.price * i.quantity),
          );
          final deliveryFee = isDelivery ? 3.00 : 0.00;
          final total = subtotal + deliveryFee;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionButton(
                        "Delivery",
                        isActive: isDelivery,
                        onTap: () => setState(() => isDelivery = true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOptionButton(
                        "Pick Up",
                        isActive: !isDelivery,
                        onTap: () => setState(() => isDelivery = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (isDelivery) ...[
                  Text(
                    "Delivery Address",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.location_on, color: darkGreen),
                      title: Text(
                        _deliveryInfo.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_deliveryInfo.address),
                      trailing: TextButton(
                        child: Text(
                          "Edit",
                          style: TextStyle(color: accentGreen),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EditAddressScreen(
                                    currentInfo: _deliveryInfo,
                                  ),
                            ),
                          );
                          if (result != null) {
                            setState(() => _deliveryInfo = result);
                          }
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    "Pick Up Location",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: darkGreen, size: 30),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Collect at Merchant Counter when 'Ready'",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ...checkoutItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${item.quantity}x  ${item.name}"),
                              Text(
                                "RM ${(item.price * item.quantity).toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      _buildCostRow(
                        "Subtotal",
                        "RM ${subtotal.toStringAsFixed(2)}",
                      ),
                      _buildCostRow(
                        "Delivery Fee",
                        isDelivery ? "RM 3.00" : "Free",
                      ),
                      const Divider(),
                      _buildCostRow(
                        "Total Payment",
                        "RM ${total.toStringAsFixed(2)}",
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isProcessing
                            ? null
                            : () => _handlePayment(checkoutItems, total),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isProcessing
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              "Place Order - RM ${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionButton(
    String text, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? sageGreen : Colors.white,
          border: Border.all(
            color: isActive ? darkGreen : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? darkGreen : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? darkGreen : Colors.black,
          ),
        ),
      ],
    );
  }
}
