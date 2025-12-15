import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uniwaste/screens/merchant/merchant_order_detail_screen.dart';
import 'package:uniwaste/screens/merchant/merchant_menu_screen.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Merchant Dashboard"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [Tab(text: "Active Orders"), Tab(text: "Past Orders")],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantMenuScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu, color: Colors.orange),
              label: const Text(
                "Manage Menu",
                style: TextStyle(color: Colors.orange),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [_OrdersList(isActive: true), _OrdersList(isActive: false)],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final bool isActive;

  const _OrdersList({required this.isActive});

  @override
  Widget build(BuildContext context) {
    // Query: Get orders sorted by date
    final Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('orderDate', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No orders found"));
        }

        // Client-side filter for Active vs Past
        // Active: paid, preparing, shipping
        // Past: completed, cancelled
        final orders =
            snapshot.data!.docs.where((doc) {
              final status = doc['status'] as String;
              if (isActive) {
                return ['paid', 'preparing', 'shipping'].contains(status);
              } else {
                return ['completed', 'cancelled'].contains(status);
              }
            }).toList();

        if (orders.isEmpty) {
          return const Center(child: Text("No orders in this category"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final data = doc.data() as Map<String, dynamic>;
            final orderId = doc.id;

            // Format Data
            final items = (data['items'] as List<dynamic>?) ?? [];
            final firstItemName =
                items.isNotEmpty ? items[0]['title'] : 'Unknown Item';
            final itemCount = items.length;
            final total = (data['totalAmount'] as num).toDouble();
            final status = data['status'];
            final Timestamp? ts = data['orderDate'];
            final dateStr =
                ts != null
                    ? DateFormat('dd MMM, hh:mm a').format(ts.toDate())
                    : '';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order #${orderId.substring(0, 5).toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      "$firstItemName ${itemCount > 1 ? '+ ${itemCount - 1} more' : ''}",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr),
                    const SizedBox(height: 8),
                    Text(
                      "RM ${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MerchantOrderDetailScreen(
                            orderId: orderId,
                            data: data,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'paid':
        color = Colors.blue;
        break;
      case 'preparing':
        color = Colors.orange;
        break;
      case 'shipping':
        color = Colors.purple;
        break;
      case 'completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
