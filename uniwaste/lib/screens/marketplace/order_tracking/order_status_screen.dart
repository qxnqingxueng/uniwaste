import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  int _getCurrentStep(String status, String method) {
    if (method == 'Pick Up') {
      if (status == 'paid') return 0;
      if (status == 'preparing') return 1;
      if (status == 'completed') return 2; // Directly completes after preparing
    } else {
      if (status == 'paid') return 0;
      if (status == 'preparing') return 1;
      if (status == 'shipping') return 2;
      if (status == 'completed') return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Order Status",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed:
              () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'paid';
          final method = data['method'] ?? 'Delivery';
          final currentStep = _getCurrentStep(status, method);

          // Define Steps based on Method
          List<Step> steps = [];

          if (method == 'Pick Up') {
            steps = [
              Step(
                title: const Text("Order Placed"),
                content: const SizedBox.shrink(),
                isActive: currentStep >= 0,
                state: currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text("Preparing"),
                content: const SizedBox.shrink(),
                isActive: currentStep >= 1,
                state: currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text("Picked Up Successfully"),
                content: const SizedBox.shrink(),
                isActive: currentStep >= 2,
                state:
                    currentStep == 2 ? StepState.complete : StepState.indexed,
              ),
            ];
          } else {
            steps = [
              Step(
                title: const Text("Order Placed"),
                content: const SizedBox.shrink(),
                isActive: currentStep >= 0,
                state: currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text("Preparing"),
                content: const SizedBox.shrink(),
                isActive: currentStep >= 1,
                state: currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text("On the Way"),
                content: const SizedBox.shrink(),
                isActive: currentStep >= 2,
                state: currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text("Delivered"),
                content: const SizedBox.shrink(),
                isActive: currentStep >= 3,
                state:
                    currentStep == 3 ? StepState.complete : StepState.indexed,
              ),
            ];
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  method == 'Pick Up' ? Icons.store : Icons.local_shipping,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),
                Text(
                  "Status: ${status.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Stepper(
                    currentStep: currentStep,
                    controlsBuilder: (_, __) => const SizedBox.shrink(),
                    steps: steps,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
