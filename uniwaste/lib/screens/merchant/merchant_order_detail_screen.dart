import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MerchantOrdersScreen extends StatelessWidget {
  final String merchantId;

  const MerchantOrdersScreen({super.key, required this.merchantId});

  Future<void> _updateStatus(
    BuildContext context,
    String orderId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': newStatus},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order updated to: ${newStatus.toUpperCase()}"),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

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
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data!.docs;

          // Filter out completed orders locally (or could do via query)
          final activeOrders =
              orders.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] != 'completed';
              }).toList();

          if (activeOrders.isEmpty)
            return const Center(child: Text("No incoming orders."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final data = activeOrders[index].data() as Map<String, dynamic>;
              final orderId = activeOrders[index].id;
              final status = data['status'] ?? 'paid';
              final method = data['method'] ?? 'Delivery';
              final items = (data['items'] as List<dynamic>?) ?? [];
              final total = (data['totalAmount'] ?? 0).toDouble();

              // --- LOGIC: 2 Buttons vs 3 Buttons ---
              String buttonText = "Loading...";
              String nextStatus = "";
              Color btnColor = Colors.blue;

              if (method == 'Pick Up') {
                // 2 Clicks: Paid -> Preparing -> Completed
                if (status == 'paid') {
                  buttonText = "Start Preparing";
                  nextStatus = "preparing";
                  btnColor = Colors.orange;
                } else if (status == 'preparing') {
                  buttonText = "Confirm Picked Up";
                  nextStatus = "completed";
                  btnColor = Colors.green;
                }
              } else {
                // 3 Clicks: Paid -> Preparing -> Shipping -> Completed
                if (status == 'paid') {
                  buttonText = "Start Preparing";
                  nextStatus = "preparing";
                  btnColor = Colors.orange;
                } else if (status == 'preparing') {
                  buttonText = "Send for Delivery";
                  nextStatus = "shipping";
                  btnColor = Colors.purple;
                } else if (status == 'shipping') {
                  buttonText = "Confirm Delivered";
                  nextStatus = "completed";
                  btnColor = Colors.green;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order #${orderId.substring(0, 5).toUpperCase()}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  method == 'Pick Up'
                                      ? Colors.orange[50]
                                      : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    method == 'Pick Up'
                                        ? Colors.orange
                                        : Colors.blue,
                              ),
                            ),
                            child: Text(
                              method.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    method == 'Pick Up'
                                        ? Colors.orange
                                        : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Status: ${status.toUpperCase()}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Divider(),
                      ...items.map(
                        (item) => Text(
                          "${item['quantity']}x ${item['title'] ?? item['name']}",
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "RM ${total.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed:
                                () =>
                                    _updateStatus(context, orderId, nextStatus),
                            child: Text(buttonText),
                          ),
                        ],
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
