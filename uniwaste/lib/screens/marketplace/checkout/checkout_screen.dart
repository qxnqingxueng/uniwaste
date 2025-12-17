import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_event.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_state.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';
import 'package:uniwaste/screens/marketplace/checkout/edit_address_screen.dart';
import 'package:uniwaste/screens/marketplace/checkout/models/delivery_info.dart';
import 'package:uniwaste/screens/marketplace/checkout/models/order_model.dart';
import 'package:uniwaste/screens/marketplace/checkout/repositories/order_repository.dart';
import 'package:uniwaste/screens/marketplace/checkout/services/payment_services.dart';
import 'package:uniwaste/screens/marketplace/checkout/widgets/voucher_page.dart';
import 'package:uniwaste/screens/marketplace/order_tracking/order_status_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryInfo _deliveryInfo = DeliveryInfo();
  final PaymentService _paymentService = PaymentService();
  final OrderRepository _orderRepository = OrderRepository();
  bool _isProcessing = false;
  bool isDelivery = true;

  Future<void> _handlePayment(List<CartItemModel> items, double amount) async {
    setState(() => _isProcessing = true);

    // 1. Stripe Payment
    final success = await _paymentService.makePayment(amount, "MYR");

    if (success) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final orderId = DateTime.now().millisecondsSinceEpoch.toString();

        // ✅ GET MERCHANT ID SAFELY (From the first item in the cart)
        final String merchantId =
            items.isNotEmpty ? (items.first.merchantId ?? '') : '';

        if (merchantId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Item has no Merchant ID")),
          );
          setState(() => _isProcessing = false);
          return;
        }

        final order = OrderModel(
          orderId: orderId,
          userId: user.uid,
          userName: user.displayName ?? "Student",
          totalAmount: amount,
          status: 'paid',
          orderDate: DateTime.now(),
          items: items,
          shippingAddress:
              isDelivery
                  ? "${_deliveryInfo.name}, ${_deliveryInfo.address}"
                  : "Self Pick-Up",
          method: isDelivery ? 'Delivery' : 'Pick Up',

          // ✅ PASS IT HERE
          merchantId: merchantId,
        );

        await _orderRepository.createOrder(order);

        if (mounted) {
          context.read<CartBloc>().add(ClearCart());
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderStatusScreen(orderId: orderId),
            ),
          );
        }
      }
    } else {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Payment Failed")));
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty)
            return const Center(child: Text("No items"));

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
                // Toggles
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

                // Dynamic Address Section
                if (isDelivery) ...[
                  const Text(
                    "Delivery Address",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(
                        _deliveryInfo.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_deliveryInfo.address),
                      trailing: TextButton(
                        child: const Text("Edit"),
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
                          if (result != null)
                            setState(() => _deliveryInfo = result);
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    "Pick Up Location",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.store, color: Colors.orange, size: 30),
                        SizedBox(width: 12),
                        Expanded(
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

                // Item Details
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

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isProcessing
                            ? null
                            : () => _handlePayment(checkoutItems, total),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
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
          color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFF1B5E20) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? const Color(0xFF1B5E20) : Colors.grey,
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
            color: isBold ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}
