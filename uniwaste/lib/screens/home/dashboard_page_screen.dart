import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/p2p/p2p_student_page.dart';
import 'package:uniwaste/screens/waste-to-resources/waste_bin_map.dart';
import 'package:uniwaste/screens/waste-to-resources/qr_scanner_page.dart';
import 'package:uniwaste/screens/marketplace/home/marketplace_home_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- POSTER LOGIC ---
  final PageController _posterController = PageController();
  int _currentPoster = 0;
  Timer? _timer;

  final List<String> _posterImages = [
    "assets/images/P2P.png",
    "assets/images/P2P.png",
    "assets/images/P2P.png",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPoster < _posterImages.length - 1) {
        _currentPoster++;
      } else {
        _currentPoster = 0;
      }

      if (_posterController.hasClients) {
        _posterController.animateToPage(
          _currentPoster,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthenticationBloc bloc) => bloc.state.user);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 100.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting
          Text(
            "Welcome, ${user?.name ?? 'Student'}!",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 1. SCROLLING POSTER CAROUSEL
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PageView.builder(
                controller: _posterController,
                itemCount: _posterImages.length,
                onPageChanged:
                    (index) => setState(() => _currentPoster = index),
                itemBuilder: (context, index) {
                  return Image.asset(
                    _posterImages[index],
                    fit: BoxFit.cover,
                    errorBuilder:
                        (ctx, err, stack) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                  );
                },
              ),
            ),
          ),

          // Dots Indicator
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_posterImages.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentPoster == index
                          ? Colors.blue
                          : Colors.grey.shade300,
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // --- 2. POINTS & VOUCHERS BUTTONS ---
          Card(
            elevation: 2,
            color: const Color.fromARGB(255, 255, 255, 255),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // BUTTON 1: MY POINTS
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        print("Points Clicked");
                      },
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: Color.fromRGBO(161, 188, 152, 1),
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "My Points",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "1,250",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // VERTICAL DIVIDER
                  const VerticalDivider(
                    thickness: 1,
                    color: Colors.grey,
                    indent: 8,
                    endIndent: 8,
                    width: 1,
                  ),

                  // BUTTON 2: VOUCHERS
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        print("Vouchers Clicked");
                      },
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer,
                              color: Color.fromRGBO(161, 188, 152, 1),
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Vouchers",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "3 Active",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. SECOND BAR: TWO CARDS (Image Top, Text Below)
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(
                    title: "Student",
                    subtitle: "Donation / Sell",
                    imagePath: "assets/images/P2P.png",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const P2PStudentPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // ✅ MERCHANT CARD (UPDATED)
                Expanded(
                  child: _buildCategoryCard(
                    title: "Merchant",
                    subtitle: "Surplus Left",
                    imagePath: "assets/images/merchant.jpg",
                    onTap: () {
                      // Navigate to Marketplace Home
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarketplaceHomeScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. MAP CARD
          SizedBox(
            height: 120,
            child: _buildBackgroundImageCard(
              title: "Waste Bin Map",
              imagePath: "assets/images/map.jpg",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WasteBinMap()),
                );
              },
              isMap: true,
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildCategoryCard({
    required String title,
    String? subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (ctx, err, stack) => Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey.shade300,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImageCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
    bool isMap = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(color: Colors.grey),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isMap) ...[
                      const Icon(
                        Icons.map_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
