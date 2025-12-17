import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ CRITICAL IMPORT: This connects the two screens
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

          // Filter out completed orders
          final activeOrders =
              orders.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] != 'completed';
              }).toList();

          if (activeOrders.isEmpty)
            return const Center(child: Text("All orders completed!"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final data = activeOrders[index].data() as Map<String, dynamic>;
              final orderId = activeOrders[index].id;
              final userName = data['userName'] ?? "Unknown User";
              final status = data['status'] ?? 'paid';
              final method = data['method'] ?? 'Delivery';
              final date = (data['orderDate'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  onTap: () {
                    // ✅ NAVIGATION NOW WORKS WITH THE IMPORT
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
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Status: ${status.toUpperCase()}"),
                      if (date != null)
                        Text(
                          DateFormat('h:mm a, dd MMM').format(date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
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
