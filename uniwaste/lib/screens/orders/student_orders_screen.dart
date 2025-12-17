import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentOrdersScreen extends StatelessWidget {
  const StudentOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view orders")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: StreamBuilder<QuerySnapshot>(
        // ⚠️ NOTE: Ensure you created the 'userId' + 'orderDate' index!
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: userId)
                .orderBy('orderDate', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (snapshot.error.toString().contains("requires an index")) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: SelectableText(
                  "⚠️ DEV ERROR: Missing Index.\n\nCheck debug console for the link to create it!\n\n${snapshot.error}",
                ),
              );
            }
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              return _buildOrderCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'unknown';
    final items = (data['items'] as List<dynamic>?) ?? [];
    final total = (data['totalAmount'] ?? 0.0).toDouble();

    // Determine Color based on status
    Color statusColor = Colors.grey;
    if (status == 'paid') statusColor = Colors.orange;
    if (status == 'accepted') statusColor = Colors.blue;
    if (status == 'ready') statusColor = Colors.purple;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display Date
                Text(
                  _formatDate(data['orderDate']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items
            ...items.map(
              (item) => Text(
                "${item['quantity']}x ${item['title']}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Paid",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "RM ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Helper text for "Ready" status
            if (status == 'ready')
              Container(
                // ✅ FIXED: Changed 'EdgeInsets.top' to 'EdgeInsets.only'
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "🎉 Your food is ready! Please pick it up.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No orders yet.",
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }
    return "";
  }
}
