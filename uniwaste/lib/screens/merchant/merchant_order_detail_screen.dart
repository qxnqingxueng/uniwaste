import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MerchantOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const MerchantOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.data,
  });

  // Function to update status
  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': newStatus},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Order updated to: $newStatus")));
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final status = data['status'] as String;
    final address = data['shippingAddress'] ?? 'Self Pick-Up';

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: Column(
        children: [
          // 1. Order Info
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Items to Prepare",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                      title: Text(item['title']),
                      subtitle: Text("Qty: ${item['quantity']}"),
                      trailing: Text("RM ${item['price']}"),
                    ),
                  ),
                ),

                const Divider(height: 30),

                const Text(
                  "Delivery Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(address),
                ),
              ],
            ),
          ),

          // 2. Action Buttons (The Controller)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Current Status: ${status.toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Buttons based on status
                  if (status == 'paid')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(context, 'preparing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text(
                          "Mark as Preparing",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  if (status == 'preparing')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(context, 'shipping'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: const Text(
                          "Mark as On The Way / Ready",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  if (status == 'shipping')
                    const Center(
                      child: Text(
                        "Waiting for customer to confirm receipt...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  if (status == 'completed')
                    const Center(
                      child: Text(
                        "✅ Order Completed",
                        style: TextStyle(color: Colors.green, fontSize: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
