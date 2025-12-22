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

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': newStatus},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status: ${newStatus.toUpperCase()}")),
        );
        if (newStatus == 'completed') {
          Navigator.pop(context); // Go back if completed
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final method = data['method'] ?? 'Delivery';
    final status = data['status'] ?? 'paid';
    final total = (data['totalAmount'] ?? 0).toDouble();

    // --- BUTTON LOGIC ---
    String btnText = "Processing";
    String nextStatus = "";
    Color btnColor = Colors.blue;
    bool showButton = true;

    if (method == 'Pick Up') {
      // Flow: Paid -> Preparing -> Ready -> Picked Up (Completed)
      if (status == 'paid') {
        btnText = "Start Preparing";
        nextStatus = "preparing";
        btnColor = Colors.orange;
      } else if (status == 'preparing') {
        btnText = "Ready for Pickup";
        nextStatus = "ready";
        btnColor = Colors.blue;
      } else if (status == 'ready') {
        btnText = "Confirm Picked Up";
        nextStatus = "completed";
        btnColor = Colors.green;
      } else {
        showButton = false;
      }
    } else {
      // Flow: Paid -> Preparing -> Shipping -> Delivered (Completed)
      if (status == 'paid') {
        btnText = "Start Preparing";
        nextStatus = "preparing";
        btnColor = Colors.orange;
      } else if (status == 'preparing') {
        btnText = "Send for Delivery";
        nextStatus = "shipping";
        btnColor = Colors.purple;
      } else if (status == 'shipping') {
        btnText = "Confirm Delivered";
        nextStatus = "completed";
        btnColor = Colors.green;
      } else {
        showButton = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Method: $method",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(status.toUpperCase()),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Items List
            const Text(
              "Items Ordered:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text("${item['quantity']}x"),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      title: Text(item['title'] ?? item['name'] ?? 'Item'),
                      trailing: Text(
                        "RM ${(item['price'] ?? 0).toStringAsFixed(2)}",
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Amount:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "RM ${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ACTION BUTTON
            if (showButton)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: btnColor),
                  onPressed: () => _updateStatus(context, nextStatus),
                  child: Text(
                    btnText,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
