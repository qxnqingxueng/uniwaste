import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/home/dashboard_page_screen.dart';

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
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
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
      // 1. TOP APP BAR (Frame Top)
      appBar: AppBar(
        title: const Text('UniWaste'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              // Triggers the global logout logic
              context
                  .read<AuthenticationBloc>()
                  .add(AuthenticationLogoutRequested());
            },
            icon: const Icon(Icons.logout),
          )
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          // Status bar color (transparent so the white AppBar shows through)
          statusBarColor: Colors.transparent, 
          statusBarIconBrightness: Brightness.dark, 
          
        ),
      ),

      // 2. MAIN BODY (The Canvas)
      // This switches content when you swipe or tap the bottom bar
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          // Dashboard
          DashboardPage(),

          // Cart / Waste
          Center(child: Text("My Cart Page\n(Add your widgets here)")),

          // Profile
          Center(child: Text("Message Page\n(Add your widgets here)")),

          // Message
          Center(child: Text("Profile Page\n(Add your widgets here)")),

          /*
          DashboardPage(),
          CartPage(),
          ProfilePage(),   //TO be updated
          */
        ],
      ),

      // 3. BOTTOM NAVIGATION (Frame Bottom)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Creates the cutout curve
        notchMargin: 10.0, // Space between the FAB and the bar
        padding: const EdgeInsets.symmetric(horizontal: 10), // Padding on ends
        height: 60, // Fixed height for the bar
        color: Colors.white, // Background color
        elevation: 10, // Shadow

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- LEFT SIDE ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNavBtn(0, Icons.home, "Home"),
                // Add space between Home and Cart if needed
                const SizedBox(width: 30),
                _buildNavBtn(1, Icons.shopping_cart, "Cart"),
              ],
            ),

            // --- RIGHT SIDE ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNavBtn(2, Icons.chat_outlined, "Chat"),
                // Add space between Chat and Profile if needed
                const SizedBox(width: 30),
                _buildNavBtn(3, Icons.person, "Profile"),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 50,
        width: 50,
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
          ),
        ),
      ),
    );
  }
}
