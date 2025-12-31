import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uniwaste/screens/merchant/dashboard/merchant_order_detail_screen.dart';

class MerchantOrdersScreen extends StatelessWidget {
  final String merchantId;

  const MerchantOrdersScreen({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Incoming Orders",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('merchantId', isEqualTo: merchantId)
                .orderBy('orderDate', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No incoming orders."));
          }

          final orders = snapshot.data!.docs;

          // Filter active orders (not completed/cancelled)
          final activeOrders =
              orders.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'pending';
                return status != 'completed' && status != 'cancelled';
              }).toList();

          if (activeOrders.isEmpty) {
            return const Center(child: Text("No active orders right now."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final data = activeOrders[index].data() as Map<String, dynamic>;
              final orderId = activeOrders[index].id;
              final status = data['status'] ?? 'pending';
              final method = data['method'] ?? 'Delivery';
              final total = (data['totalAmount'] ?? 0).toDouble();
              final date = (data['orderDate'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  // ✅ TAP TO GO TO DETAILS (Where the buttons are)
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
                  leading: CircleAvatar(
                    backgroundColor:
                        method == 'Pick Up'
                            ? Colors.orange[100]
                            : Colors.blue[100],
                    child: Icon(
                      method == 'Pick Up' ? Icons.store : Icons.local_shipping,
                      color: method == 'Pick Up' ? Colors.orange : Colors.blue,
                    ),
                  ),
                  title: Text(
                    "Order #${orderId.substring(0, 5).toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${status.toString().toUpperCase()}"),
                      if (date != null)
                        Text(
                          DateFormat('dd MMM, h:mm a').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "RM ${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
