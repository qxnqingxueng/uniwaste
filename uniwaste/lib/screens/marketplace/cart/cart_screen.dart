import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/screens/marketplace/widgets/marketplace_app_bar.dart';
import 'package:uniwaste/screens/marketplace/checkout/widgets/voucher_page.dart'; // We will create this below

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isDelivery = true;
  String? _selectedVoucher; // To store selected voucher

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const MarketplaceAppBar(title: "My Cart", showCart: false),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(child: Text("Your cart is empty"));
          }

          double deliveryFee = _isDelivery ? 3.00 : 0.00;
          double discount = _selectedVoucher != null ? 5.00 : 0.00; // Mock logic
          double finalTotal = state.subtotal + deliveryFee - discount;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                // 1. DELIVERY TOGGLE & MAP
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(child: _buildTab("Delivery", _isDelivery, () => setState(() => _isDelivery = true))),
                            Expanded(child: _buildTab("Pick-Up", !_isDelivery, () => setState(() => _isDelivery = false))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Dynamic Map/Address Area
                      _isDelivery ? _buildDeliveryInfo() : _buildPickupInfo(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),

                // 2. ORDER ITEMS
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Kafe Lestari", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton(
                            onPressed: () => Navigator.pop(context), // Go back to add items
                            child: const Text("Add Items", style: TextStyle(color: Colors.green)),
                          )
                        ],
                      ),
                      const Divider(),
                      ...state.items.map((item) => _buildCartItemTile(item)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. VOUCHERS / OFFERS
                GestureDetector(
                  onTap: () async {
                    // Navigate to Voucher Page and wait for result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VoucherPage()),
                    );
                    if (result != null) {
                      setState(() => _selectedVoucher = result);
                    }
                  },
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text("Apply Voucher", style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (_selectedVoucher != null)
                          Text(_selectedVoucher!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. BILL SUMMARY
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row("Subtotal", "RM ${state.subtotal.toStringAsFixed(2)}"),
                      _row("Delivery Fee", "RM ${deliveryFee.toStringAsFixed(2)}"),
                      if (_selectedVoucher != null)
                        _row("Voucher Discount", "-RM ${discount.toStringAsFixed(2)}", color: Colors.green),
                      const Divider(height: 24),
                      _row("Total Payment", "RM ${finalTotal.toStringAsFixed(2)}", isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // TODO: Go to Payment
            },
            child: const Text("Place Order", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTab(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
        ),
        child: Center(
          child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildPickupInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fake Map
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(image: AssetImage('assets/images/map.jpg'), fit: BoxFit.cover),
          ),
          child: const Center(child: Icon(Icons.location_on, color: Colors.red)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Kafe Lestari (Asian)", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text("Universiti Malaya, 50603 Kuala Lumpur", style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 8),
              Text("Distance: 0.8 km", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return const Row(
      children: [
        Icon(Icons.access_time_filled, color: Colors.green),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Delivery to: Kolej Kediaman 12", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Est. Time: 15 - 20 mins (1.2 km)", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        )
      ],
    );
  }

  Widget _buildCartItemTile(cartItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
            child: Text("${cartItem.quantity}x", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cartItem.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (cartItem.notes.isNotEmpty)
                  Text("Note: ${cartItem.notes}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text("RM ${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}