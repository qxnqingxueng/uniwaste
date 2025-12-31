import 'package:flutter/material.dart';
import 'package:uniwaste/screens/home/dashboard_page_screen.dart';
import 'package:uniwaste/screens/waste-to-resources/qr_scanner_page.dart';
import 'package:uniwaste/screens/profile/profile_screen.dart';
import 'package:uniwaste/screens/social/feed_screen.dart';
import 'package:uniwaste/screens/shop/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
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

  Widget _buildNavBtn(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onTabTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color:
                isSelected
                    ? const Color.fromRGBO(119, 136, 115, 1.0)
                    : const Color.fromRGBO(208, 209, 208, 1),
            size: 28,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color:
                  isSelected
                      ? const Color.fromRGBO(119, 136, 115, 1.0)
                      : const Color.fromRGBO(208, 209, 208, 1),
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

      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          DashboardPage(),
          ShopPage(),
          FeedScreen(),
          ProfileScreen(),
        ],
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0.3,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
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
                  _buildNavBtn(1, Icons.store, "Shop"),
                ],
              ),
              // --- RIGHT SIDE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
