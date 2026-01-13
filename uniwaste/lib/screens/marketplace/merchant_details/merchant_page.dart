import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final Color midGreen = const Color(0xFFA1BC98);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 1. HEADER (Unchanged) ---
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.black,
                        ),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                              ),
                            ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: BlocBuilder<CartBloc, CartState>(
                        builder: (context, state) {
                          if (state is CartLoaded && state.items.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
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
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeaderImage(widget.imageUrl),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. MERCHANT INFO SECTION ---
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('merchants')
                      .doc(widget.merchantId)
                      .snapshots(),
              builder: (context, merchantSnap) {
                if (!merchantSnap.hasData) return const SizedBox.shrink();

                final mData =
                    merchantSnap.data!.data() as Map<String, dynamic>? ?? {};
                final address = mData['address'] ?? 'Address not available';
                final phone = mData['phone'] ?? '';
                final List<dynamic> rawCats = mData['categories'] ?? [];
                final categories = rawCats.map((e) => e.toString()).toList();

                final double baseRating = (mData['rating'] ?? 4.0).toDouble();
                final double deliveryFee =
                    (mData['deliveryFee'] ?? 3.00).toDouble();
                final String deliveryTime = mData['deliveryTime'] ?? '25 mins';

                return StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('orders')
                          .where('merchantId', isEqualTo: widget.merchantId)
                          .snapshots(),
                  builder: (context, orderSnap) {
                    int orderCount =
                        orderSnap.hasData ? orderSnap.data!.docs.length : 0;
                    double bonusRating = (orderCount / 20).floor() * 0.1;
                    double finalRating = baseRating + bonusRating;
                    if (finalRating > 5.0) finalRating = 5.0;

                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.merchantName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            categories.join(" • ") +
                                (categories.isNotEmpty
                                    ? " • \$\$\$"
                                    : "\$\$\$"),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                finalRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                " ($orderCount+)",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "•",
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                deliveryTime,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "•",
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Delivery: RM ${deliveryFee.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  phone,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- 3. SECTION HEADER ---
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: const Text(
                "Menu",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // --- 4. MENU ITEMS LIST ---
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
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Center(child: Text("No items available.")),
                  ),
                );
              }

              final items =
                  snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final qty = data['quantity'] ?? 0;
                    final isAvailable = data['isAvailable'] ?? true;
                    return qty > 0 && isAvailable == true;
                  }).toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final doc = items[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildMenuItem(context, doc.id, data);
                }, childCount: items.length),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // --- Helper: Header Image ---
  Widget _buildHeaderImage(String data) {
    if (data.isEmpty) return Container(color: Colors.grey[300]);
    if (data.startsWith('http')) return Image.network(data, fit: BoxFit.cover);
    try {
      return Image.memory(base64Decode(data), fit: BoxFit.cover);
    } catch (e) {
      return Container(color: Colors.grey[300]);
    }
  }

  // --- Helper: FANCY MENU ITEM CARD ---
  Widget _buildMenuItem(
    BuildContext context,
    String itemId,
    Map<String, dynamic> data,
  ) {
    Widget itemImage;
    if (data['imagePath'] != null && data['imagePath'].toString().isNotEmpty) {
      try {
        itemImage = Image.memory(
          base64Decode(data['imagePath']),
          fit: BoxFit.cover,
        );
      } catch (e) {
        itemImage = Container(
          color: Colors.grey[200],
          child: const Icon(Icons.fastfood, color: Colors.grey),
        );
      }
    } else {
      itemImage = Container(
        color: Colors.grey[200],
        child: const Icon(Icons.fastfood, color: Colors.grey),
      );
    }

    // Logic: Quantity Left
    final quantityLeft = data['quantity'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 100, height: 100, child: itemImage),
            ),

            const SizedBox(width: 16),

            // 2. Details Column
            Expanded(
              child: SizedBox(
                height: 100, // Match image height to align bottom row
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Section: Name & Qty
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Unknown Item',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // ✅ FANCY QUANTITY BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 12,
                                color: Colors.deepOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$quantityLeft left",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom Section: Price & Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "RM ${(data['price'] ?? 0).toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkGreen,
                          ),
                        ),

                        // ✅ FANCY ADD BUTTON (Aligned neatly)
                        InkWell(
                          onTap: () {
                            context.read<CartBloc>().add(
                              AddItem(
                                CartItemModel(
                                  id: itemId,
                                  name: data['name'] ?? 'Unknown',
                                  price: (data['price'] ?? 0).toDouble(),
                                  merchantId: widget.merchantId,
                                  quantity: 1,
                                  imagePath: data['imagePath'],
                                ),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${data['name']} added!"),
                                duration: const Duration(milliseconds: 600),
                                backgroundColor: darkGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: darkGreen,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: darkGreen.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              "Add",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
      ),
    );
  }
}
