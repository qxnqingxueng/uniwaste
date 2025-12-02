import 'package:flutter/material.dart';
import 'package:uniwaste/screens/marketplace/merchant_details/merchant_page.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  // Dummy data for filters
  final List<String> _categories = [
    "Halal",
    "Vegetarian",
    "No Pork",
    "Under RM5",
    "Free Delivery",
    "Rating 4.5+",
  ];

  // Dummy data for Merchants
  final List<Map<String, dynamic>> _merchants = [
    {
      "name": "Kafe Lestari (Asian)",
      "image":
          "assets/images/merchant.jpg", // Ensure this asset exists or use a network URL
      "rating": 4.8,
      "time": "10-15 min",
      "surplusCount": 5,
      "closingTime": "8:00 PM",
      "isHalal": true,
    },
    {
      "name": "The Green Salad Bar",
      "image": "assets/images/merchant.jpg",
      "rating": 4.5,
      "time": "5-10 min",
      "surplusCount": 2,
      "closingTime": "9:30 PM",
      "isHalal": true,
    },
    {
      "name": "Bites & Beans Cafe",
      "image": "assets/images/merchant.jpg",
      "rating": 4.2,
      "time": "20-30 min",
      "surplusCount": 0,
      "closingTime": "6:00 PM",
      "isHalal": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: const Icon(Icons.location_on, color: Colors.red),
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
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to Cart Screen
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search "Nasi Lemak"',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),

          // 2. Filters
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return _FilterChipWidget(label: _categories[index]);
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 3. Title
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Surplus Near You",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 4. Merchant List
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final merchant = _merchants[index];
                return _MerchantCard(
                  name: merchant['name'],
                  rating: merchant['rating'],
                  time: merchant['time'],
                  surplusCount: merchant['surplusCount'],
                  closingTime: merchant['closingTime'],
                  imageUrl: merchant['image'],
                  onTap: () {
                    // --- NAVIGATION LOGIC ---
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MerchantPage(
                              merchantName: merchant['name'],
                              imageUrl: merchant['image'],
                            ),
                      ),
                    );
                  },
                );
              }, childCount: _merchants.length),
            ),
          ),
        ],
      ),
    );
  }
}

// --- LOCAL WIDGETS ---

class _FilterChipWidget extends StatelessWidget {
  final String label;
  const _FilterChipWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final String name;
  final double rating;
  final String time;
  final int surplusCount;
  final String closingTime;
  final String imageUrl;
  final VoidCallback onTap;

  const _MerchantCard({
    required this.name,
    required this.rating,
    required this.time,
    required this.surplusCount,
    required this.closingTime,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (c, o, s) => Container(color: Colors.grey[300]),
                    ),
                  ),
                ),
                if (surplusCount > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$surplusCount Surplus Items Left",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "$time • Closes $closingTime",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
