import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/screens/home/dashboard_page_screen.dart';
import 'package:uniwaste/screens/marketplace/cart/cart_screen.dart';
import 'package:uniwaste/screens/waste-to-resources/qr_scanner_page.dart';
import 'package:uniwaste/screens/profile/profile_screen.dart';
import 'package:uniwaste/screens/social/feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Controller to handle page switching programmatically (From Main Branch)
  final PageController _pageController = PageController();

  /// Tracks the currently active tab
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Smoothly animate to the selected page (Teammate's feature)
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Helper to build a custom navigation button (From Main Branch logic)
  Widget _buildNavBtn(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    // Standardized colors from Main Branch
    final Color activeColor = const Color.fromRGBO(
      119,
      136,
      115,
      1.0,
    ); // #778873
    final Color inactiveColor = const Color.fromRGBO(208, 209, 208, 1);

    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onTabTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 28),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? activeColor : inactiveColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows the body to flow behind the FAB notch
      // 2. MAIN BODY (The Canvas)
      // Uses PageView (from Main Branch) to allow animations, but loads YOUR screens
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics:
            const NeverScrollableScrollPhysics(), // Disables swipe to prevent accidental tab switching
        children: const [
          // Index 0: Dashboard
          DashboardPage(),

          // Index 1: Cart (Your Feature)
          CartScreen(),

          // Index 2: Social/Feed (Your Feature)
          FeedScreen(),

          // Index 3: Profile
          ProfileScreen(),
        ],
      ),

      // 3. BOTTOM NAVIGATION (Frame Bottom)
      // Kept Main Branch's design because it includes the QR Scanner FAB
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0.3,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(), // The cutout for the FAB
          notchMargin: 10.0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 60,
          color: Colors.white,
          elevation: 0,
          clipBehavior: Clip.none,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- LEFT SIDE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(left: 5)),
                  _buildNavBtn(0, Icons.home, "Home"),
                  const SizedBox(width: 25),
                  // Linked to Index 1 (Your Cart)
                  _buildNavBtn(1, Icons.shopping_cart, "Cart"),
                ],
              ),

              // --- RIGHT SIDE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linked to Index 2 (Your Social)
                  _buildNavBtn(2, Icons.group_outlined, "Social"),
                  const SizedBox(width: 25),
                  _buildNavBtn(3, Icons.person, "Profile"),
                  const Padding(padding: EdgeInsets.only(right: 5)),
                ],
              ),
            ],
          ),
        ),
      ),

      // The QR Scanner Button (Main Branch Feature)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 60,
        width: 60,
        child: FloatingActionButton(
          backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
          elevation: 0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QrScanScreen()),
            );
          },
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: Color.fromRGBO(119, 136, 115, 1.0),
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
