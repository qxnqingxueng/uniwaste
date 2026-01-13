import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  // Theme Colors
  final Color bgCream = const Color(0xFFF1F3E0);
  final Color darkGreen = const Color(0xFF778873);
  final Color white = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Track Order",
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: darkGreen));
          }

          // ✅ FIXED: Check 'snapshot.data!.exists' properly
          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
            return const Center(child: Text("Order not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          final method = data['method'] ?? 'Delivery';
          final items = (data['items'] as List<dynamic>?) ?? [];
          final total = (data['totalAmount'] ?? 0).toDouble();

          // ✅ PROGRESS LOGIC
          int currentStep = 0;
          if (status == 'pending' || status == 'paid') {
            currentStep = 1;
          } else if (status == 'preparing')
            currentStep = 2;
          else if (status == 'on_the_way' ||
              status == 'ready' ||
              status == 'shipping')
            currentStep = 3;
          else if (status == 'completed')
            currentStep = 4;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- 1. STATUS CARD ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(status, method),
                        color: white,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getStatusTitle(status, method),
                        style: TextStyle(
                          color: white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method == 'Pick Up' ? "Store Pickup" : "Home Delivery",
                        style: TextStyle(
                          color: white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- 2. TIMELINE ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildTimelineStep(
                        1,
                        currentStep,
                        "Order Placed",
                        "We have received your order",
                        false,
                      ),
                      _buildTimelineStep(
                        2,
                        currentStep,
                        "Preparing",
                        "Merchant is preparing your food",
                        false,
                      ),
                      _buildTimelineStep(
                        3,
                        currentStep,
                        method == 'Pick Up' ? "Ready for Pickup" : "On The Way",
                        method == 'Pick Up'
                            ? "Waiting at the counter"
                            : "Rider is delivering your food",
                        false,
                      ),
                      _buildTimelineStep(
                        4,
                        currentStep,
                        method == 'Pick Up' ? "Collected" : "Delivered",
                        "Enjoy your meal!",
                        true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- 3. SUMMARY ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${item['quantity']}x ${item['name']}"),
                              Text(
                                "RM ${(item['price'] ?? 0).toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "RM ${total.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStep(
    int step,
    int currentStep,
    String title,
    String subtitle,
    bool isLast,
  ) {
    bool isCompleted = currentStep >= step;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? darkGreen : Colors.grey[200],
                border: Border.all(
                  color: isCompleted ? darkGreen : Colors.grey,
                ),
              ),
              child:
                  isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: currentStep > step ? darkGreen : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status, String method) {
    if (status == 'completed') return Icons.check_circle_outline;
    if (status == 'preparing') return Icons.restaurant;
    return method == 'Pick Up' && status == 'ready'
        ? Icons.shopping_bag_outlined
        : Icons.delivery_dining;
  }

  String _getStatusTitle(String status, String method) {
    if (status == 'pending') return "Order Placed";
    if (status == 'preparing') return "Preparing Food";
    if (status == 'completed') return "Completed";
    return method == 'Pick Up' && status == 'ready'
        ? "Ready for Pickup"
        : "On The Way";
  }
}
