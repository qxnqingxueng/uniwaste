import 'package:flutter/material.dart';

// 1. Import Teammate's Dashboard
import 'package:uniwaste/screens/home/dashboard_page_screen.dart';

// 2. Import Cart Screen (Instead of Marketplace Home)
import 'package:uniwaste/screens/marketplace/cart/cart_screen.dart';

// 3. Import Social Screen
import 'package:uniwaste/screens/social/feed_screen.dart';

// 4. Import Profile Screen
import 'package:uniwaste/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // The 4 main pages: Home, Cart, Social, Profile
  final List<Widget> _pages = [
    const DashboardPage(), // Index 0
    const CartScreen(), // Index 1 (CHANGED TO CART)
    const FeedScreen(), // Index 2
    const ProfileScreen(), // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFA1BC98),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // ✅ CHANGED ICON & LABEL
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
