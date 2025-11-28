import 'package:flutter/material.dart';
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
              context.read<AuthenticationBloc>().add(AuthenticationLogoutRequested());
            },
            icon: const Icon(Icons.logout),
          )
        ],
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
          Center(child: Text("Profile Page\n(Add your widgets here)")),
          
          /*
          DashboardPage(),
          CartPage(),
          ProfilePage(),   //TO be updated
          */
        ],
      ),

      // 3. BOTTOM NAVIGATION (Frame Bottom)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue, // Highlight color
        unselectedItemColor: Colors.grey, // Inactive color
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}