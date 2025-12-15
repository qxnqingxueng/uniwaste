import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_state.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_event.dart'; // ✅ Needed to clear cart
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';
import 'package:uniwaste/screens/marketplace/checkout/models/delivery_info.dart';
import 'package:uniwaste/screens/marketplace/order_tracking/order_status_screen.dart'; // ✅ Navigate here after success
import 'package:uniwaste/services/payment_service.dart'; // ✅ Your Stripe Service

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Toggle between Delivery and Pick Up
  bool isDelivery = true;
  bool _isProcessing = false; // ✅ To show loading on button

  // Hardcoded address for demo (Connect to Profile in real app)
  final DeliveryInfo _deliveryInfo = DeliveryInfo(
    name: "Ng Xue Qing | (+60) 10-459 9806",
    address: "4, Tingkat Kerapu 4, Taman Kerapu, 13400 Butterworth...",
  );

  // ---------------------------------------------------------------------------
  // 1. BACKEND LOGIC: Create Order in Firestore
  // ---------------------------------------------------------------------------
  Future<void> _createOrder(
    List<CartItemModel> items,
    double totalAmount,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Generate a new Document Reference
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      final orderData = {
        'orderId': orderRef.id,
        'userId': user.uid,
        'userName': user.displayName ?? 'Student',
        'totalAmount': totalAmount,
        'status': 'paid', // Initial status
        'orderDate': FieldValue.serverTimestamp(),
        'method': isDelivery ? 'Delivery' : 'Pick Up',
        'address': isDelivery ? _deliveryInfo.address : 'Self Pick-Up',
        'items':
            items
                .map(
                  (item) => {
                    'title': item.title,
                    'price': item.price,
                    'quantity': item.quantity,
                    // 'merchantId': item.merchantId // Add this if you have it in CartItemModel
                  },
                )
                .toList(),
      };

      // Write to Firestore
      await orderRef.set(orderData);

      // Clear the Cart
      if (mounted) {
        context.read<CartBloc>().add(ClearCart());
      }

      // Navigate to Tracking Screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderStatusScreen(orderId: orderRef.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Order Creation Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. PAYMENT LOGIC: Handle Stripe
  // ---------------------------------------------------------------------------
  Future<void> _handlePayment(
    List<CartItemModel> items,
    double totalAmount,
  ) async {
    print("--------------------------------------------------");
    print("BUTTON WAS CLICKED! STARTING PAYMENT...");
    print("--------------------------------------------------");

    setState(() => _isProcessing = true);

    // ... rest of your code

    // Call your Payment Service
    // Note: totalAmount passed to Stripe needs to be precise
    final success = await PaymentService.instance.makePayment(
      context,
      totalAmount,
    );

    if (success) {
      await _createOrder(items, totalAmount);
    } else {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter only selected items
          final checkoutItems = state.items.where((i) => i.isSelected).toList();

          // Calculate totals
          final double subtotal = checkoutItems.fold(
            0,
            (sum, item) => sum + (item.price * item.quantity),
          );
          final double deliveryFee = isDelivery ? 3.00 : 0.00;
          final double totalPayment = subtotal + deliveryFee;

          if (checkoutItems.isEmpty) {
            return const Center(child: Text("No items selected for checkout"));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. DELIVERY / PICKUP TOGGLE
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

                      // 2. ADDRESS SECTION (Only if Delivery)
                      if (isDelivery) ...[
                        const Text(
                          "Delivery Address",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _deliveryInfo.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _deliveryInfo.address,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        const Divider(height: 32),
                      ],

                      // 3. ORDER DETAILS
                      const Text(
                        "Order Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...checkoutItems.map((item) => _buildOrderItem(item)),
                      const Divider(height: 32),

                      // 4. COST BREAKDOWN
                      _buildCostRow(
                        "Subtotal",
                        "RM ${subtotal.toStringAsFixed(2)}",
                      ),
                      const SizedBox(height: 8),
                      _buildCostRow(
                        "Delivery Fee",
                        "RM ${deliveryFee.toStringAsFixed(2)}",
                      ),
                      const SizedBox(height: 24),

                      // 5. VOUCHER SECTION
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer, color: Colors.orange),
                            const SizedBox(width: 12),
                            const Text(
                              "Platform Voucher",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(
                              "Select Voucher",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // BOTTOM PAYMENT BAR
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Total Payment",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          "RM ${totalPayment.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA1BC98), // App Theme Green
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      // ✅ 3. LOGIC INTEGRATION
                      onPressed:
                          _isProcessing
                              ? null
                              : () =>
                                  _handlePayment(checkoutItems, totalPayment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA1BC98),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isProcessing
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "Place Order",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

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
          color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFFA1BC98) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? const Color(0xFFA1BC98) : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "x${item.quantity}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (item.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Note: ${item.notes}",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            "RM ${(item.price * item.quantity).toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
