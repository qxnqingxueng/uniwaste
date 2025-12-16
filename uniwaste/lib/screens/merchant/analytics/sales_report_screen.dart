import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesReportScreen extends StatelessWidget {
  final String merchantId;

  const SalesReportScreen({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Report")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('merchantId', isEqualTo: merchantId)
                .where(
                  'status',
                  isEqualTo: 'completed',
                ) // Only count COMPLETED orders
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // 1. Calculate Totals
          final orders = snapshot.data!.docs;
          double totalRevenue = 0;
          int totalItemsSold = 0;

          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            totalRevenue += (data['totalAmount'] ?? 0.0);

            // Count items if available
            if (data['items'] != null) {
              final itemsList = data['items'] as List;
              totalItemsSold += itemsList.length;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Revenue Card
                _buildStatCard(
                  "Total Revenue",
                  "RM ${totalRevenue.toStringAsFixed(2)}",
                  Icons.attach_money,
                  Colors.green,
                ),
                const SizedBox(height: 16),

                // Orders Count Card
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Orders Completed",
                        "${orders.length}",
                        Icons.check_circle,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        "Items Rescued",
                        "$totalItemsSold",
                        Icons.fastfood,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Text(
                  "Recent Transactions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // List of recent sales
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final data = orders[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(
                          Icons.monetization_on,
                          color: Colors.green,
                        ),
                        title: Text(
                          "RM ${(data['totalAmount'] ?? 0).toStringAsFixed(2)}",
                        ),
                        subtitle: Text(data['userName'] ?? 'Customer'),
                        trailing: Text(
                          (data['orderDate'] as Timestamp?)
                                  ?.toDate()
                                  .toString()
                                  .substring(0, 10) ??
                              '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No sales data yet", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
