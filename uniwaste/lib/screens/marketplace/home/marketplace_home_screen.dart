import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/merchant_bloc/merchant_bloc.dart';
import 'package:uniwaste/screens/marketplace/merchant_details/merchant_page.dart';
import 'package:merchant_repository/merchant_repository.dart';
import 'package:uniwaste/screens/marketplace/order_tracking/order_status_screen.dart';

// Marketplace Home Screen
class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";

  // Categories List (Can be dynamic based on your data)
  final List<String> _categories = [
    "All",
    "Halal",
    "Vegetarian",
    "No Pork",
    "Cheap Eats",
  ];

  // Colors from your Current version
  final Color bgCream = const Color(0xFFF1F3E0);
  final Color darkGreen = const Color(0xFF778873);
  final Color midGreen = const Color(0xFFA1BC98);

  @override
  void initState() {
    super.initState();
    // start loading data asap the screen opens
    context.read<MerchantBloc>().add(LoadMerchants());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgCream,

      // --- FLOATING TRACK ORDER BUTTON ---
      floatingActionButton:
          user == null
              ? null
              : Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: StreamBuilder<QuerySnapshot>(
                  //Listen to 'orders' collection for THIS user
                  stream:
                      FirebaseFirestore.instance
                          .collection('orders')
                          .where('userId', isEqualTo: user.uid)
                          .orderBy('orderDate', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    DocumentSnapshot? activeOrder;
                    try {
                      activeOrder = snapshot.data!.docs.firstWhere((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'completed';
                        return status != 'completed' && status != 'cancelled';
                      });
                    } catch (e) {
                      activeOrder = null;
                    }

                    if (activeOrder == null) return const SizedBox.shrink();

                    return FloatingActionButton.extended(
                      heroTag: "tracker_btn",
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => OrderStatusScreen(
                                    orderId: activeOrder!.id,
                                  ),
                            ),
                          ),
                      backgroundColor: darkGreen,
                      elevation: 10,
                      icon: const Icon(
                        Icons.delivery_dining,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Track Order",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),

      // --- BODY: CUSTOM SCROLL VIEW WITH SLIVERS ---
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 1. FANCY APP BAR (From Incoming Code) ---
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: bgCream,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: darkGreen, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Marketplace",
              style: TextStyle(
                color: darkGreen,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            centerTitle: false,

            // Search Bar inside flexible space
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                color: bgCream,
                child: TextField(
                  controller: _searchController,
                  // Rebuild UI when typing to filter the list
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search for food...',
                    prefixIcon: Icon(Icons.search, color: darkGreen),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- 2. STICKY CATEGORY LIST (From Incoming Code) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 40,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.9, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return ActionChip(
                        label: Text(cat),
                        backgroundColor: isSelected ? midGreen : Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : darkGreen,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? midGreen : Colors.grey.shade300,
                        ),
                        shape: const StadiumBorder(),
                        onPressed:
                            () => setState(() {
                              if (_selectedCategory == cat && cat != "All") {
                                _selectedCategory = "All";
                              } else {
                                _selectedCategory = cat;
                              }
                            }),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // --- 3. MERCHANT LIST (From Current Code - Uses BLoC Data) ---
          BlocBuilder<MerchantBloc, MerchantState>(
            builder: (context, state) {
              if (state is MerchantLoading) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              if (state is MerchantLoaded) {
                // Apply Filtering Logic on Real Data
                final merchants =
                    state.merchants.where((m) {
                      //Search Text Match
                      final matchesSearch = m.name.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      );
                      // Category Match
                      bool matchesCategory = true;
                      if (_selectedCategory != "All") {
                        // For simplicity, assume categories are stored as a list of strings
                        matchesCategory = m.categories.contains(
                          _selectedCategory,
                        );
                      }

                      return matchesSearch &&
                          matchesCategory &&
                          m.id.isNotEmpty;
                    }).toList();

                if (merchants.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text("No merchants found")),
                    ),
                  );
                }

                // Display Filtered Merchants
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final merchant = merchants[index];
                      return _FancyMerchantCard(
                        merchant: merchant,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MerchantPage(
                                      merchantId: merchant.id,
                                      merchantName: merchant.name,
                                      imageUrl: merchant.imageUrl,
                                    ),
                              ),
                            ),
                      );
                    }, childCount: merchants.length),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// --- FANCY MERCHANT CARD WIDGET (From Incoming Code) ---
class _FancyMerchantCard extends StatelessWidget {
  final Merchant merchant;
  final VoidCallback onTap;

  const _FancyMerchantCard({required this.merchant, required this.onTap});

  Widget _buildImage(String data) {
    if (data.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.store));
    }
    if (data.startsWith('http')) {
      return Image.network(data, fit: BoxFit.cover);
    } else {
      try {
        return Image.memory(base64Decode(data), fit: BoxFit.cover);
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image),
        );
      }
    }
  }

  @override
  // Build the Fancy Merchant Card UI
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: merchant.id,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: _buildImage(merchant.imageUrl),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Shows Category Tags instead of "Cafe" or Description
                    Text(
                      merchant.categories.isNotEmpty
                          ? merchant.categories.join(" • ")
                          : "Restaurant",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Rating and Delivery Fee Row
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          merchant.rating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          // Shows dynamic fee or Free
                          merchant.deliveryFee == 0
                              ? "Free Delivery"
                              : "RM ${merchant.deliveryFee.toStringAsFixed(2)} Delivery",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
