import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniwaste/screens/merchant/analytics/sales_report_screen.dart';
import 'package:uniwaste/screens/merchant/dashboard/merchant_orders_screen.dart';
import 'package:uniwaste/screens/merchant/menu/merchant_menu_screen.dart';
import 'package:uniwaste/screens/merchant/settings/merchant_settings_screen.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Dashboard")),
        body: const Center(
          child: Text("Please log in to access the merchant dashboard."),
        ),
      );
    }

    final merchantId = user.uid;
    final merchantName = user.displayName ?? 'Merchant';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Merchant Dashboard",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INCOMING ORDERS (All logic is here now)
            _DashboardCard(
              title: "Incoming Orders",
              subtitle: "Manage Delivery & Pickups",
              icon: Icons.receipt_long,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            MerchantOrdersScreen(merchantId: merchantId),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 2. MANAGE MENU
            _DashboardCard(
              title: "Manage Menu",
              subtitle: "Add or edit surplus food items",
              icon: Icons.restaurant_menu,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MerchantMenuScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // 3. SALES REPORT
            _DashboardCard(
              title: "Sales Report",
              subtitle: "Track earnings",
              icon: Icons.analytics_outlined,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SalesReportScreen(merchantId: merchantId),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 4. SHOP SETTINGS
            _DashboardCard(
              title: "Shop Settings",
              subtitle: "Update name, address & photo",
              icon: Icons.store_mall_directory,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Reusable Card Widget
class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
}
