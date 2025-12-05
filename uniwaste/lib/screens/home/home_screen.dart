import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/home/dashboard_page_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uniwaste/screens/profile/profile_screen.dart';
import 'package:uniwaste/screens/social/forum_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Controller to handle page switching programmatically
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
    // Smoothly animate to the selected page
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

  // Helper to build a custom navigation button
  Widget _buildNavBtn(int index, IconData icon, String label) {
    // Check if this tab is currently active
    final bool isSelected = _currentIndex == index;

    return MaterialButton(
      minWidth: 40, // Keeps buttons compact
      onPressed: () => _onTabTapped(index),
      splashColor: Colors.transparent, // Removes the splash effect
      highlightColor: Colors.transparent, // Removes the highlight effect on tap
      padding: const EdgeInsets.all(0), // Remove default padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? Color.fromRGBO(119, 136, 115, 1.0)
                : Color.fromRGBO(208, 209, 208, 1),
            size: 28,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? Color.fromRGBO(119, 136, 115, 1.0)
                  : Color.fromRGBO(208, 209, 208, 1),
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
      extendBody: true,

      // 2. MAIN BODY (The Canvas)
      // This switches content when you swipe or tap the bottom bar
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // Dashboard
          const DashboardPage(),

          // Cart / Waste
          Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: const Center(
                child: Text("My Cart Page\n(Add your widgets here)")),
          ),

          // Message
          const ForumScreen(),

          // Profile
          const ProfileScreen(),

          /*
          DashboardPage(),
          CartPage(),
          ProfilePage(),   //TO be updated
          */
        ],
      ),

      // 3. BOTTOM NAVIGATION (Frame Bottom)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), // Shadow color
              blurRadius: 10, // How soft the shadow is
              spreadRadius: 0.3, // How thick the shadow is
              offset: const Offset(0, -3), // Negative Y moves the shadow UP
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(), // Creates the cutout curve
          notchMargin: 10.0, // Space between the FAB and the bar
          padding:
              const EdgeInsets.symmetric(horizontal: 10), // Padding on ends
          height: 60, // Fixed height for the bar
          color: Colors.white, // Background color
          elevation: 0, // Shadow
          clipBehavior: Clip.none,

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- LEFT SIDE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 5)),
                  _buildNavBtn(0, Icons.home, "Home"),
                  // Add space between Home and Cart
                  const SizedBox(width: 25),
                  _buildNavBtn(1, Icons.shopping_cart, "Cart"),
                ],
              ),

              // --- RIGHT SIDE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavBtn(2, Icons.chat_outlined, "Chat"),
                  // Add space between Chat and Profile
                  const SizedBox(width: 25),
                  _buildNavBtn(3, Icons.person, "Profile"),
                  Padding(padding: const EdgeInsets.only(right: 5))
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 60,
        width: 60,
        child: FloatingActionButton(
          backgroundColor: Color.fromRGBO(119, 136, 115, 1.0),
          elevation: 0,
          onPressed: () => debugPrint("Qr Button pressed."),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
                width: 1, color: Color.fromRGBO(119, 136, 115, 1.0)),
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
