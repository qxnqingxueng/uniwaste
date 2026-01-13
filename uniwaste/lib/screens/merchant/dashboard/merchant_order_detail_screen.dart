import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MerchantOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const MerchantOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.data,
  });

  // --- FUNCTION TO UPDATE ORDER STATUS ---
  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Update Global Orders
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': newStatus},
      );

      // 2. Update Merchant's Sub-collection (Sync Fix)
      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to: ${newStatus.toUpperCase()}"),
            backgroundColor: Colors.green,
          ),
        );
        if (newStatus == 'completed') {
          Navigator.pop(context); // Go back to list when done
        }
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
  // --- BUILD UI ---
  Widget build(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final method = data['method'] ?? 'Delivery';
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final total = (data['totalAmount'] ?? 0).toDouble();

    // --- CUSTOMER INFO SYNC ---
    final customerName = data['userName'] ?? 'Unknown Guest';
    final customerEmail = data['userEmail'] ?? 'No email provided';

    // Address Logic: Default to "None" if empty or placeholder
    String rawAddress = data['shippingAddress'] ?? '';
    if (rawAddress.isEmpty || rawAddress == "Please select an address") {
      rawAddress = "None";
    }
    final shippingAddress = rawAddress;

    // --- BUTTON LOGIC ---
    String btnText = "Completed";
    String nextStatus = "";
    Color btnColor = Colors.grey;
    bool showButton = true;

    if (method == 'Pick Up') {
      if (status == 'pending' || status == 'paid') {
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
      if (status == 'pending' || status == 'paid') {
        btnText = "Start Preparing";
        nextStatus = "preparing";
        btnColor = Colors.orange;
      } else if (status == 'preparing') {
        btnText = "Send for Delivery";
        nextStatus = "on_the_way";
        btnColor = Colors.purple;
      } else if (status == 'on_the_way' || status == 'shipping') {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    method.toUpperCase(),
                    style: TextStyle(
                      color: method == 'Pick Up' ? Colors.orange : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor:
                      method == 'Pick Up' ? Colors.orange[50] : Colors.blue[50],
                ),
                Chip(
                  label: Text(status.toUpperCase()),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- CUSTOMER INFO CARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                children: [
                  // Name
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Email
                  Row(
                    children: [
                      const Icon(Icons.email, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customerEmail,
                          style: const TextStyle(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address (Synced)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shippingAddress, // ✅ Displays "None" or real address
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),

            // --- ITEMS LIST ---
            const Text(
              "Items Ordered",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item['quantity']}x  ${item['title'] ?? item['name'] ?? 'Item'}",
                    ),
                    Text("RM ${(item['price'] ?? 0).toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),
            const Divider(),

            // --- TOTAL ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
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
            const SizedBox(height: 40),

            // --- ACTION BUTTON ---
            if (showButton)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _updateStatus(context, nextStatus),
                  child: Text(
                    btnText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
