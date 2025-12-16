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

  Future<void> _handlePayment(List<CartItemModel> items, double amount) async {
    setState(() => _isProcessing = true);

    // 1. Stripe Payment
    final success = await _paymentService.makePayment(amount, "MYR");

    if (success) {
      // 2. Create Order
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final orderId = DateTime.now().millisecondsSinceEpoch.toString();

        final order = OrderModel(
          orderId: orderId,
          userId: user.uid,
          totalAmount: amount,
          status: 'paid',
          orderDate: DateTime.now(),
          items: items,
          shippingAddress: "${_deliveryInfo.name}, ${_deliveryInfo.address}",
        );

        await _orderRepository.createOrder(order);

        if (mounted) {
          // Clear Cart
          context.read<CartBloc>().add(ClearCart());
          // Navigate to Success/Tracking
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
          final deliveryFee = 3.00;
          final total = subtotal + deliveryFee;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Address
                ListTile(
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
                              (_) =>
                                  EditAddressScreen(currentInfo: _deliveryInfo),
                        ),
                      );
                      if (result != null)
                        setState(() => _deliveryInfo = result);
                    },
                  ),
                ),
                const Divider(),
                // Items
                Expanded(
                  child: ListView.builder(
                    itemCount: checkoutItems.length,
                    itemBuilder:
                        (_, i) => ListTile(
                          title: Text(checkoutItems[i].name),
                          trailing: Text(
                            "RM ${(checkoutItems[i].price * checkoutItems[i].quantity).toStringAsFixed(2)}",
                          ),
                        ),
                  ),
                ),
                // Voucher
                ListTile(
                  leading: const Icon(
                    Icons.confirmation_number,
                    color: Colors.orange,
                  ),
                  title: const Text("Apply Voucher"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VoucherPage()),
                      ),
                ),
                const Divider(),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Payment",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "RM ${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                            : const Text(
                              "Place Order",
                              style: TextStyle(color: Colors.white),
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
}
