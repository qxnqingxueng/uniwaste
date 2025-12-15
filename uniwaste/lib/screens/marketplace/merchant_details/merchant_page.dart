import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_state.dart';
import 'package:uniwaste/screens/marketplace/cart/cart_screen.dart';
import 'package:uniwaste/screens/marketplace/merchant_details/widgets/item_details_bottom_sheet.dart';

class MerchantPage extends StatelessWidget {
  final String merchantId; // ✅ NEW: Need ID to fetch menu
  final String merchantName;
  final String imageUrl;

  const MerchantPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.imageUrl,
  });

  // Helper to safely load network or asset images
  Widget _buildSafeImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
      );
    } else if (path.length > 200) {
      // It's likely a base64 string
      try {
        return Image.memory(base64Decode(path), fit: fit);
      } catch (e) {
        return Container(color: Colors.grey[200]);
      }
    } else {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. App Bar
          SliverAppBar(
            backgroundColor: const Color(0xFFF1F3E0),
            expandedHeight: 200.0,
            pinned: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Colors.black,
                ),
                padding: const EdgeInsets.only(left: 6),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                merchantName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Hero(
                tag: merchantId,
                child: _buildSafeImage(imageUrl),
              ),
            ),
          ),

          // 2. Info Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      Text(
                        " 4.8 (120+ ratings) • Asian • Halal",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Surplus Menu (50% OFF)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 3. 🔥 REAL MENU FROM FIREBASE
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('merchants')
                    .doc(merchantId)
                    .collection('menu')
                    .where(
                      'isAvailable',
                      isEqualTo: true,
                    ) // Only show active items
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text("No items available right now.")),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final itemId = docs[index].id;

                  final String itemName = data['title'] ?? 'Unknown';
                  final double price = (data['price'] ?? 0).toDouble();
                  final int surplus = data['surplus'] ?? 0;
                  final String itemImg =
                      data['image'] ?? imageUrl; // Fallback to merchant image

                  return Column(
                    children: [
                      ListTile(
                        leading: SizedBox(
                          width: 60,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildSafeImage(itemImg),
                          ),
                        ),
                        title: Text(itemName),
                        subtitle: Text(
                          "Qty: $surplus • RM ${price.toStringAsFixed(2)}",
                        ),
                        trailing: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                        ),
                        onTap: () {
                          // Add to Cart Logic
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder:
                                (context) => ItemDetailsBottomSheet(
                                  itemId: itemId,
                                  itemName: itemName,
                                  price: price,
                                  merchantName: merchantName,
                                  itemImage:
                                      itemImg, // Pass base64 string or url
                                ),
                          );
                        },
                      ),
                      const Divider(),
                    ],
                  );
                }, childCount: docs.length),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // 4. Floating Cart Button
      bottomSheet: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              child: Text(
                "View Cart (${state.items.length} items) - RM ${state.totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
