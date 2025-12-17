import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/merchant_bloc/merchant_bloc.dart';
import 'package:uniwaste/screens/marketplace/merchant_details/merchant_page.dart';
import 'package:merchant_repository/merchant_repository.dart';
import 'package:uniwaste/screens/marketplace/order_tracking/order_status_screen.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";

  // Categories
  final List<String> _categories = [
    "All",
    "Halal",
    "Vegetarian",
    "No Pork",
    "Cheap Eats",
  ];

  @override
  void initState() {
    super.initState();
    context.read<MerchantBloc>().add(LoadMerchants());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ✅ TRACKER BUTTON (Lifted up to avoid Bottom Menu)
      floatingActionButton:
          user == null
              ? null
              : Padding(
                // 👇 100px Padding ensures it floats ABOVE your bottom menu
                padding: const EdgeInsets.only(bottom: 100.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('orders')
                          .where('userId', isEqualTo: user.uid)
                          .orderBy('orderDate', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    // 1. Safety Checks
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // 2. Find active order (Filter out completed/cancelled)
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

                    // 3. Hide if no active order
                    if (activeOrder == null) return const SizedBox.shrink();

                    // 4. Show Button
                    return FloatingActionButton.extended(
                      heroTag: "tracker_btn",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    OrderStatusScreen(orderId: activeOrder!.id),
                          ),
                        );
                      },
                      backgroundColor: const Color(0xFF1B5E20),
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

      // ✅ MAIN BODY (Your original UI)
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. App Bar
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Location",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  "Universiti Malaya",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search for food...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Category Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 40,
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
                      backgroundColor: isSelected ? Colors.green : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      onPressed: () => setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. Merchant List
          BlocBuilder<MerchantBloc, MerchantState>(
            builder: (context, state) {
              if (state is MerchantLoading)
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              if (state is MerchantError)
                return SliverToBoxAdapter(
                  child: Center(child: Text("Error: ${state.message}")),
                );

              if (state is MerchantLoaded) {
                final merchants =
                    state.merchants.where((m) {
                      final matchesSearch = m.name.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      );
                      bool matchesCategory =
                          _selectedCategory == "All" ||
                          m.categories.contains(_selectedCategory);
                      return matchesSearch &&
                          matchesCategory &&
                          m.id.isNotEmpty;
                    }).toList();

                if (merchants.isEmpty)
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: Text("No merchants found")),
                    ),
                  );

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final merchant = merchants[index];
                      return _FancyMerchantCard(
                        merchant: merchant,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MerchantPage(
                                    merchantId: merchant.id,
                                    merchantName: merchant.name,
                                    imageUrl: merchant.imageUrl,
                                  ),
                            ),
                          );
                        },
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

class _FancyMerchantCard extends StatelessWidget {
  final Merchant merchant;
  final VoidCallback onTap;

  const _FancyMerchantCard({required this.merchant, required this.onTap});

  Widget _buildImage(String data) {
    if (data.isEmpty)
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.store, size: 50, color: Colors.grey),
      );
    if (data.startsWith('http')) {
      return Image.network(
        data,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
      );
    } else {
      try {
        return Image.memory(
          base64Decode(data),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        );
      }
    }
  }

  @override
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
                    const SizedBox(height: 4),
                    Text(
                      merchant.description.isNotEmpty
                          ? merchant.description
                          : "No description available",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        Text(
                          merchant.rating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "RM 3.00 Delivery",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
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
