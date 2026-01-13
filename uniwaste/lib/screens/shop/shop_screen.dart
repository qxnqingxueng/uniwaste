import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uniwaste/screens/p2p/p2p_student_page.dart';
import 'package:uniwaste/screens/marketplace/home/marketplace_home_screen.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  // Access Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Marketplace",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F3E0), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PROMO BANNER
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B8E23), Color(0xFF8FBC8F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B8E23).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.shopping_basket,
                          size: 150,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Zero Waste Hero 🌍",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Check out the latest donations\nfrom your community.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 2. MAIN NAVIGATION (P2P vs Merchant)
                const Text(
                  "Explore Markets",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Student Exchange Card
                _buildMarketCard(
                  context,
                  title: "Student Exchange",
                  subtitle: "Peer-to-peer sharing",
                  icon: Icons.people_outline,
                  color: const Color(0xFFFFF3E0), // Light Orange
                  iconColor: Colors.orange,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const P2PStudentPage(),
                        ),
                      ),
                ),
                const SizedBox(height: 16),

                // Merchant Deals Card
                _buildMarketCard(
                  context,
                  title: "Merchant Deals",
                  subtitle: "Official campus vendors",
                  icon: Icons.storefront,
                  color: const Color(0xFFE8F5E9), // Light Green
                  iconColor: Colors.green,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarketplaceHomeScreen(),
                        ),
                      ),
                ),

                const SizedBox(height: 30),

                // 3. FRESH ARRIVALS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Fresh Arrivals",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to full list (P2P page)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const P2PStudentPage(),
                          ),
                        );
                      },
                      child: const Text("See All"),
                    ),
                  ],
                ),

                SizedBox(
                  height: 190,
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        _db
                            .collection('food_listings')
                            .where('status', isEqualTo: 'available')
                            .orderBy('created_at', descending: true)
                            .limit(10) // Increased limit to ensure we have enough after filtering
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allDocs = snapshot.data?.docs ?? [];

                      // ✅ ADDED: Filter out expired items
                      final validDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final Timestamp? expiryTs = data['expiry_date'] as Timestamp?;
                        
                        if (expiryTs != null) {
                          if (expiryTs.toDate().isBefore(DateTime.now())) {
                            return false; // Item is expired
                          }
                        }
                        return true;
                      }).toList();

                      if (validDocs.isEmpty) {
                        return Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text("No active listings yet."),
                        );
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        // Take max 5 items after filtering to keep layout consistent
                        itemCount: validDocs.length > 5 ? 5 : validDocs.length,
                        itemBuilder: (context, index) {
                          final data = validDocs[index].data() as Map<String, dynamic>;
                          return _buildRealItemCard(data);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 80), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildMarketCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRealItemCard(Map<String, dynamic> data) {
    // 1. Decode Image Blob
    Uint8List? imageBytes;
    if (data['image_blob'] != null && data['image_blob'] is Blob) {
      imageBytes = (data['image_blob'] as Blob).bytes;
    }

    // 2. Parse Price/Free
    final bool isFree = data['is_free'] ?? true;
    final double price = (data['price'] ?? 0).toDouble();
    final String priceText = isFree ? "Free" : "RM ${price.toStringAsFixed(2)}";

    // 3. Parse Title
    final String title = data['description'] ?? "Food Item";

    // 4. Parse Time (Simple Logic)
    String timeText = "Just now";
    if (data['created_at'] != null) {
      final Timestamp ts = data['created_at'];
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inMinutes < 60) {
        timeText = "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        timeText = "${diff.inHours}h ago";
      } else {
        timeText = "${diff.inDays}d ago";
      }
    }

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE SECTION
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                child:
                    imageBytes != null
                        ? Image.memory(imageBytes, fit: BoxFit.cover)
                        : const Icon(
                          Icons.fastfood,
                          color: Colors.grey,
                          size: 40,
                        ),
              ),
            ),
          ),
          // INFO SECTION
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  priceText,
                  style: TextStyle(
                    color: isFree ? const Color(0xFF6B8E23) : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}