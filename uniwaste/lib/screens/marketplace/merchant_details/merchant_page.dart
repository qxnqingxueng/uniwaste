import 'package:flutter/material.dart';
import 'package:uniwaste/screens/marketplace/cart/cart_screen.dart';
import 'package:uniwaste/screens/marketplace/merchant_details/item_details_bottom_sheet.dart'; // Ensure this exists

class MerchantPage extends StatelessWidget {
  final String merchantName;
  final String imageUrl;

  const MerchantPage({
    super.key,
    required this.merchantName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 1. We removed the fixed 'appBar' to prevent the double-arrow bug.
      // The SliverAppBar below acts as the only header.
      body: CustomScrollView(
        slivers: [
          // 2. The Scrolling Header
          SliverAppBar(
            // Your System Color
            backgroundColor: const Color(0xFFF1F3E0),
            expandedHeight: 200.0,
            floating: false,
            pinned: true, // Keeps the bar stuck to top when scrolling
            // Custom Back Button (iOS Style bubble)
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
                padding: const EdgeInsets.only(
                  left: 6,
                ), // Visually center the arrow
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Custom Cart Button (Top Right)
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],

            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              // Title fades in when collapsed
              title: Text(
                merchantName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Hero Animation for smooth transition
              background: Hero(
                tag: merchantName,
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (ctx, err, stack) =>
                          Container(color: const Color(0xFFF1F3E0)),
                ),
              ),
            ),
          ),

          // 3. Merchant Info Section
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

                  // Surplus Alert Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Hurry! Only 5 surplus items left. Closing in 45 mins.",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Surplus Menu (50% OFF)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 4. Menu Items List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    // Food Image Placeholder
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF1F3E0,
                        ), // System color background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                    title: Text(
                      "Surplus Item #${index + 1}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      "Original: RM 12.00",
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "RM 6.00",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "50% OFF",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Open the Bottom Sheet we created earlier
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
                              itemName: "Surplus Item #${index + 1}",
                              price: 6.00,
                            ),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ), // Separator line
                ],
              );
            }, childCount: 6),
          ),

          // Spacer so the last item isn't hidden behind the floating button
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // 5. Floating "View Cart" Button
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20), // Dark Green
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
          child: const Text(
            "View Cart (2 items) - RM 12.00",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
