import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ✅ Imports for Cart Logic
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';
import 'package:uniwaste/screens/marketplace/cart/cart_screen.dart';

class MerchantPage extends StatefulWidget {
  final String merchantId;
  final String merchantName;
  final String imageUrl;

  const MerchantPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.imageUrl,
  });

  @override
  State<MerchantPage> createState() => _MerchantPageState();
}

class _MerchantPageState extends State<MerchantPage> {
  // Theme Colors
  final Color darkGreen = const Color(0xFF778873);
  final Color bgCream = const Color(0xFFF1F3E0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: CustomScrollView(
        slivers: [
          // --- 1. FANCY HEADER (App Bar) ---
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: darkGreen,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Cart Icon with Badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, state) {
                        if (state is CartLoaded && state.items.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${state.items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.merchantName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Merchant Header Image
                  _buildHeaderImage(widget.imageUrl),
                  // Gradient Overlay for readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. MENU ITEMS LIST ---
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('merchants')
                    .doc(widget.merchantId)
                    .collection('items')
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(child: Text("No items available today.")),
                  ),
                );
              }

              // ✅ FILTER: Only show items with Qty > 0 and IsAvailable == true
              final items =
                  snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final qty = data['quantity'] ?? 0;
                    // Treat missing 'isAvailable' as true by default
                    final isAvailable = data['isAvailable'] ?? true;
                    return qty > 0 && isAvailable == true;
                  }).toList();

              if (items.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(child: Text("All items sold out!")),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildMenuItem(context, doc.id, data);
                  }, childCount: items.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Helper: Header Image Decoder ---
  Widget _buildHeaderImage(String data) {
    if (data.isEmpty) {
      return Container(color: Colors.grey);
    }
    if (data.startsWith('http')) {
      return Image.network(data, fit: BoxFit.cover);
    }
    try {
      return Image.memory(base64Decode(data), fit: BoxFit.cover);
    } catch (e) {
      return Container(color: Colors.grey);
    }
  }

  // --- Helper: Menu Item Card ---
  Widget _buildMenuItem(
    BuildContext context,
    String itemId,
    Map<String, dynamic> data,
  ) {
    // Decode Item Image safely
    Widget itemImage;
    if (data['imagePath'] != null && data['imagePath'].toString().isNotEmpty) {
      try {
        itemImage = Image.memory(
          base64Decode(data['imagePath']),
          fit: BoxFit.cover,
        );
      } catch (e) {
        itemImage = const Icon(Icons.fastfood, color: Colors.grey);
      }
    } else {
      itemImage = const Icon(Icons.fastfood, color: Colors.grey);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: SizedBox(width: 100, height: 100, child: itemImage),
          ),

          // Info Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Surplus: ${data['quantity']} left",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RM ${(data['price'] ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),

                      // ✅ ADD TO CART BUTTON
                      InkWell(
                        onTap: () {
                          // 1. Add item to Bloc
                          context.read<CartBloc>().add(
                            AddItem(
                              CartItemModel(
                                id: itemId,
                                name: data['name'] ?? 'Unknown',
                                price: (data['price'] ?? 0).toDouble(),
                                merchantId: widget.merchantId,
                                quantity: 1,
                                // ✅ CRITICAL FIX: Pass Image to Cart!
                                imagePath: data['imagePath'],
                              ),
                            ),
                          );

                          // 2. Show Feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${data['name']} added to cart!"),
                              backgroundColor: darkGreen,
                              duration: const Duration(milliseconds: 800),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: darkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
