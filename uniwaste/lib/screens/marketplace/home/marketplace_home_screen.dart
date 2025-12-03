import 'package:flutter/material.dart';
import 'package:uniwaste/screens/marketplace/merchant_details/merchant_page.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";
  List<Map<String, dynamic>> _displayedMerchants = [];

  // --- DATA SOURCE ---
  final List<Map<String, dynamic>> _allMerchants = [
    {
      "id": "m1", // Unique ID for Hero Animation
      "name": "Kafe Lestari (Asian)",
      "tags": ["Halal", "Asian", "Rice"],
      "rating": 4.8,
      "time": "10-15 min",
      "surplusCount": 5,
      "closingTime": "8:00 PM",
      "deliveryFee": 3.00,
      "image": "assets/images/merchant.jpg",
      "popularity": 95,
    },
    {
      "id": "m2",
      "name": "The Green Salad Bar",
      "tags": ["Vegetarian", "Healthy", "Salad"],
      "rating": 4.5,
      "time": "5-10 min",
      "surplusCount": 2,
      "closingTime": "9:30 PM",
      "deliveryFee": 0.00,
      "image": "https://via.placeholder.com/150",
      "popularity": 80,
    },
    {
      "id": "m3",
      "name": "Bites & Beans Cafe",
      "tags": ["Western", "Coffee", "No Pork"],
      "rating": 4.2,
      "time": "20-30 min",
      "surplusCount": 0,
      "closingTime": "6:00 PM",
      "deliveryFee": 2.50,
      "image": "assets/images/merchant.jpg",
      "popularity": 60,
    },
  ];

  final List<String> _categories = [
    "All",
    "Halal",
    "Vegetarian",
    "No Pork",
    "Free Delivery",
    "Rating 4.5+",
  ];

  @override
  void initState() {
    super.initState();
    _runFilterLogic();
  }

  void _runFilterLogic() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _displayedMerchants =
          _allMerchants.where((merchant) {
            final nameMatches = merchant['name'].toLowerCase().contains(query);
            bool categoryMatches = true;
            if (_selectedCategory != "All") {
              if (_selectedCategory == "Free Delivery") {
                categoryMatches = merchant['deliveryFee'] == 0;
              } else if (_selectedCategory == "Rating 4.5+") {
                categoryMatches = merchant['rating'] >= 4.5;
              } else {
                List<String> tags = merchant['tags'];
                categoryMatches = tags.contains(_selectedCategory);
              }
            }
            return nameMatches && categoryMatches;
          }).toList();
      _displayedMerchants.sort(
        (a, b) => b['popularity'].compareTo(a['popularity']),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(), // iOS style bouncy scroll
        slivers: [
          // --- 1. FANCY APP BAR (Sliver) ---
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true, // Keeps the "Location" visible
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
            title: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Column(
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
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
            ],
            // Search Bar inside the flexible space for "Collapse" effect
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _runFilterLogic(),
                  decoration: InputDecoration(
                    hintText: 'Search "Nasi Lemak"',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), // Pill shape
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- 2. STICKY CATEGORY LIST ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 40,
                // ShaderMask makes the list fade out at the edge (Visual Polish)
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
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ActionChip(
                          label: Text(cat),
                          backgroundColor:
                              isSelected ? Colors.green : Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? Colors.green
                                    : Colors.grey.shade300,
                          ),
                          shape: const StadiumBorder(),
                          onPressed: () {
                            setState(() {
                              if (_selectedCategory == cat && cat != "All") {
                                _selectedCategory = "All";
                              } else {
                                _selectedCategory = cat;
                              }
                              _runFilterLogic();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // --- 3. MERCHANT LIST WITH HERO ANIMATION ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver:
                _displayedMerchants.isEmpty
                    ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text("No merchants found"),
                        ),
                      ),
                    )
                    : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final merchant = _displayedMerchants[index];
                        return _FancyMerchantCard(
                          merchant: merchant,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MerchantPage(
                                      merchantName: merchant['name'],
                                      imageUrl: merchant['image'],
                                      // Pass ID for Hero tag (Optional if you update MerchantPage)
                                    ),
                              ),
                            );
                          },
                        );
                      }, childCount: _displayedMerchants.length),
                    ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _FancyMerchantCard extends StatelessWidget {
  final Map<String, dynamic> merchant;
  final VoidCallback onTap;

  const _FancyMerchantCard({required this.merchant, required this.onTap});

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
            spreadRadius: 0,
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
              // HERO ANIMATION WRAPPER
              Hero(
                tag:
                    merchant['name'], // This connects the image to the next screen
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: Image.asset(
                          merchant['image'],
                          fit: BoxFit.cover,
                          errorBuilder:
                              (c, o, s) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.store),
                              ),
                        ),
                      ),
                    ),
                    if (merchant['surplusCount'] > 0)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${merchant['surplusCount']} Left",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            merchant['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                merchant['rating'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${merchant['tags'].join(' • ')}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          merchant['time'],
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            "•",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Text(
                          merchant['deliveryFee'] == 0
                              ? "Free Delivery"
                              : "RM ${merchant['deliveryFee']} Delivery",
                          style: TextStyle(
                            color: Colors.grey[600],
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
