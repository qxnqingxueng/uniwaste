import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uniwaste/screens/marketplace/order_tracking/widgets/tracking_map.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  // Helper to map DB status to Stepper Index
  int _getStatusStep(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 0; // Order Placed
      case 'preparing':
        return 1; // Preparing
      case 'shipping':
        return 2; // On the Way
      case 'completed':
        return 3; // Delivered
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Order Status",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            // Pop until we hit the Marketplace Home (removes checkout/cart from stack)
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
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
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String;
          final currentStep = _getStatusStep(status);

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. The Map
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TrackingMap(),
                ),

                // 2. Order ID & Time
                Text(
                  "Order #${orderId.substring(0, 8).toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Status: ${status.toUpperCase()}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const Divider(height: 30),

                // 3. Status Timeline (Stepper)
                Stepper(
                  physics: const NeverScrollableScrollPhysics(),
                  currentStep: currentStep,
                  controlsBuilder:
                      (context, details) =>
                          const SizedBox.shrink(), // Hide default buttons
                  steps: [
                    Step(
                      title: const Text("Order Placed"),
                      content: const Text("We have received your order."),
                      isActive: currentStep >= 0,
                      state:
                          currentStep > 0
                              ? StepState.complete
                              : StepState.indexed,
                    ),
                    Step(
                      title: const Text("Preparing"),
                      content: const Text(
                        "The merchant is preparing your food.",
                      ),
                      isActive: currentStep >= 1,
                      state:
                          currentStep > 1
                              ? StepState.complete
                              : StepState.indexed,
                    ),
                    Step(
                      title: const Text("On the Way"),
                      content: const Text("Rider is picking up your order."),
                      isActive: currentStep >= 2,
                      state:
                          currentStep > 2
                              ? StepState.complete
                              : StepState.indexed,
                    ),
                    Step(
                      title: const Text("Delivered"),
                      content: const Text("Enjoy your meal!"),
                      isActive: currentStep >= 3,
                      state:
                          currentStep == 3
                              ? StepState.complete
                              : StepState.indexed,
                    ),
                  ],
                ),

                // 4. Cancel Button (Only visible if Order Placed)
                if (currentStep < 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: OutlinedButton(
                      onPressed: () {
                        // Add cancellation logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Cancellation not implemented yet"),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Cancel Order",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // 5. Confirm Delivery Button (Only if "On the Way" / Shipping)
                if (currentStep == 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Update DB to completed
                        try {
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(orderId)
                              .update({'status': 'completed'});

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Order Completed! Enjoy your meal.",
                                ),
                              ),
                            );
                            // Exit tracking to home
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Confirm Receipt",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
