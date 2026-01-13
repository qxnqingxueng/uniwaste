import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/screens/marketplace/checkout/checkout_screen.dart';

// Screen displaying the user's cart
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3E0),
      appBar: AppBar(
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty) {
            return const Center(child: Text("Your cart is empty"));
          }

          return Stack(
            children: [
              // 1. SCROLLABLE LIST
              Positioned.fill(
                bottom: 100, // Space for the bottom bar
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = state.items[index];

                    // Image Logic
                    Widget imageWidget;
                    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
                      try {
                        imageWidget = Image.memory(
                          base64Decode(item.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                              ),
                        );
                      } catch (e) {
                        imageWidget = const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        );
                      }
                    } else {
                      imageWidget = const Icon(
                        Icons.fastfood,
                        color: Colors.grey,
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Checkbox (Compact)
                          SizedBox(
                            width: 30,
                            child: Checkbox(
                              value: item.isSelected,
                              activeColor: const Color(0xFF778873),
                              onChanged:
                                  (_) => context.read<CartBloc>().add(
                                    ToggleSelection(item.id),
                                  ),
                            ),
                          ),

                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: imageWidget,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Name & Price (Flexible to prevent squash)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis, // ✅ Fixes word breaking
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "RM ${item.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Qty Controls & Trash (Compact Row)
                          Row(
                            mainAxisSize: MainAxisSize.min, // Keep tight
                            children: [
                              _buildQtyBtn(Icons.remove, () {
                                if (item.quantity > 1) {
                                  context.read<CartBloc>().add(
                                    UpdateQuantity(item.id, item.quantity - 1),
                                  );
                                }
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  "${item.quantity}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildQtyBtn(Icons.add, () {
                                context.read<CartBloc>().add(
                                  UpdateQuantity(item.id, item.quantity + 1),
                                );
                              }),
                              const SizedBox(width: 8),
                              // Trash Icon
                              InkWell(
                                onTap: () {
                                  context.read<CartBloc>().add(
                                    RemoveItem(item.id),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 2. PINNED CHECKOUT BAR (Most Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    30,
                  ), // Extra bottom padding for safe area
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          Text(
                            "RM ${state.totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF778873),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF778873),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                            state.totalAmount > 0
                                ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CheckoutScreen(),
                                  ),
                                )
                                : null,
                        child: const Text(
                          "Checkout",
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
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper for small qty buttons
  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}
