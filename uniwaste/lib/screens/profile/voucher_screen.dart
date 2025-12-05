import 'package:flutter/material.dart';

class VoucherScreen extends StatelessWidget {
  const VoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA1BC98),
        elevation: 0,
        title: const Text(
          "My Vouchers",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildVoucherCard(
            title: "10% Discount",
            brand: "UniWaste Partner Café",
            expiry: "Valid until 20 Dec 2025",
          ),
          _buildVoucherCard(
            title: "Free Drink Upgrade",
            brand: "Bubble Tea Shop",
            expiry: "Valid until 31 Jan 2026",
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard({
    required String title,
    required String brand,
    required String expiry,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA1BC98),
            )),
          const SizedBox(height: 6),
          Text(brand,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            )),
          const SizedBox(height: 10),
          Text(expiry,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            )),
        ],
      ),
    );
  }
}
