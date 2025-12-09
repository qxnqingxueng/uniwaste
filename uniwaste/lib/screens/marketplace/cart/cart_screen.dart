import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';
import 'package:uniwaste/screens/marketplace/checkout/edit_address_screen.dart';
import 'package:uniwaste/screens/marketplace/checkout/models/delivery_info.dart';
import 'package:uniwaste/screens/marketplace/widgets/marketplace_app_bar.dart';
import 'package:uniwaste/screens/marketplace/checkout/edit_address_screen.dart';
import 'package:uniwaste/screens/marketplace/checkout/models/delivery_info.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Store Delivery preference per Merchant (Key: MerchantName, Value: isDelivery)
  final Map<String, bool> _merchantDeliveryStatus = {};

  DeliveryInfo _userInfo = DeliveryInfo();

  Map<String, List<CartItemModel>> _groupItemsByMerchant(
    List<CartItemModel> items,
  ) {
    final Map<String, List<CartItemModel>> grouped = {};
    for (var item in items) {
      if (!grouped.containsKey(item.merchantName)) {
        grouped[item.merchantName] = [];
        // Default to Delivery (true) for new merchants
        if (!_merchantDeliveryStatus.containsKey(item.merchantName)) {
          _merchantDeliveryStatus[item.merchantName] = true;
        }
      }
      grouped[item.merchantName]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const MarketplaceAppBar(title: "Checkout", showCart: false),

      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(child: Text("Your cart is empty"));
          }

          final groupedItems = _groupItemsByMerchant(state.items);

          // Calculate Grand Total
          double grandTotal = 0;
          groupedItems.forEach((merchantName, items) {
            double merchantSubtotal = items.fold(
              0,
              (sum, item) => sum + item.total,
            );
            double shipping =
                _merchantDeliveryStatus[merchantName]! ? 3.00 : 0.00;
            grandTotal += (merchantSubtotal + shipping);
          });

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. ADDRESS BAR (Shopee Style) - Global for Delivery
                _buildAddressHeader(),

                // 2. ITEMS LIST (Grouped by Merchant)
                ...groupedItems.entries.map((entry) {
                  return _buildShopeeMerchantSection(entry.key, entry.value);
                }).toList(),

                // 3. PAYMENT METHOD SECTION (Shopee Style)
                _buildPaymentMethodSection(),

                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          );
        },
      ),

      // 4. BOTTOM CHECKOUT BAR
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          // Re-calculate total for display (same logic as above)
          final groupedItems = _groupItemsByMerchant(state.items);
          double grandTotal = 0;
          groupedItems.forEach((merchantName, items) {
            double merchantSubtotal = items.fold(
              0,
              (sum, item) => sum + item.total,
            );
            double shipping =
                _merchantDeliveryStatus[merchantName]! ? 3.00 : 0.00;
            grandTotal += (merchantSubtotal + shipping);
          });

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Total Payment",
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        "RM ${grandTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFFE94F37), // Shopee Orange
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Place Order Logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94F37),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      "Place Order",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  // 1. Merchant Section (Like Shopee)
  Widget _buildShopeeMerchantSection(
    String merchantName,
    List<CartItemModel> items,
  ) {
    bool isDelivery = _merchantDeliveryStatus[merchantName] ?? true;
    double subtotal = items.fold(0, (sum, item) => sum + item.total);
    double shippingFee = isDelivery ? 3.00 : 0.00;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Merchant Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.storefront, size: 18),
                const SizedBox(width: 8),
                Text(
                  merchantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // B. Items List
          ...items.map((item) => _buildItemRow(item)).toList(),

          const Divider(height: 1, thickness: 0.5),

          // C. Message to Seller
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text("Message:", style: TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Expanded(
                  child: const Text(
                    "Please leave message...",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // D. Shipping Option (Clickable)
          InkWell(
            onTap: () {
              // Toggle Delivery Mode for THIS merchant only
              setState(() {
                _merchantDeliveryStatus[merchantName] = !isDelivery;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(
                0xFFF8FBF8,
              ), // Slight green tint for shipping area
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Shipping Option",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        isDelivery ? "RM 3.00" : "Free",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDelivery
                                  ? "Standard Delivery"
                                  : "Self Collection Point",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isDelivery
                                  ? "Receive by tomorrow"
                                  : "Pick up at $merchantName",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // E. Merchant Total
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order Total (${items.length} items):",
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  "RM ${(subtotal + shippingFee).toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Color(0xFFE94F37),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(CartItemModel item) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFAFAFA), // Slightly darker background
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              image: const DecorationImage(
                image: AssetImage(
                  'assets/images/merchant.jpg',
                ), // Replace with item.image
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                if (item.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      "Note: ${item.notes}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "RM ${item.price.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "x${item.quantity}",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressHeader() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditAddressScreen(currentInfo: _userInfo),
          ),
        );
        if (result != null && result is DeliveryInfo)
          setState(() => _userInfo = result);
      },
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.red],
                  stops: [0.5, 0.5],
                  tileMode: TileMode.repeated,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFE94F37),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_userInfo.name} | ${_userInfo.phone}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          _userInfo.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.monetization_on_outlined, color: Color(0xFFE94F37)),
              SizedBox(width: 8),
              Text("Payment Method", style: TextStyle(fontSize: 14)),
            ],
          ),
          Row(
            children: const [
              Text(
                "ShopeePay",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
