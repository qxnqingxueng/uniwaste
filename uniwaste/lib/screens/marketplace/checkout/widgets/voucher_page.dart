import 'package:flutter/material.dart';

class VoucherPage extends StatelessWidget {
  const VoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Apply Voucher",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Enter voucher code",
                suffixIcon: TextButton(
                  onPressed: () {},
                  child: const Text("APPLY"),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(),
          // Voucher List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildVoucherTile(
                  context,
                  "WELCOME5",
                  "RM 5.00 OFF",
                  "Min. spend RM 10",
                ),
                _buildVoucherTile(
                  context,
                  "FREEDEL",
                  "Free Delivery",
                  "Valid for today only",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherTile(
    BuildContext context,
    String code,
    String title,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(
          Icons.local_activity,
          color: Colors.orange,
          size: 30,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, code); // Return the code to Cart Screen
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Use", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
