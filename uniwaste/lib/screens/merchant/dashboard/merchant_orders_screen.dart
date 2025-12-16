import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Run 'flutter pub add intl' if missing
import 'package:uniwaste/blocs/merchant_order_bloc/merchant_order_bloc.dart';
import 'package:uniwaste/blocs/merchant_order_bloc/merchant_order_event.dart';
import 'package:uniwaste/blocs/merchant_order_bloc/merchant_order_state.dart';

class MerchantOrdersScreen extends StatefulWidget {
  final String merchantId; // Passed from login or profile

  const MerchantOrdersScreen({super.key, required this.merchantId});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 🚀 Trigger the Bloc to load data immediately
    context.read<MerchantOrderBloc>().add(
      LoadMerchantOrders(widget.merchantId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Orders"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          tabs: const [Tab(text: "Active"), Tab(text: "History")],
        ),
      ),
      body: BlocBuilder<MerchantOrderBloc, MerchantOrderState>(
        builder: (context, state) {
          if (state is MerchantOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MerchantOrdersError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          if (state is MerchantOrdersLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(state.activeOrders, isActive: true),
                _buildOrderList(state.pastOrders, isActive: false),
              ],
            );
          }
          return const Center(child: Text("No orders found."));
        },
      ),
    );
  }

  Widget _buildOrderList(
    List<Map<String, dynamic>> orders, {
    required bool isActive,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.soup_kitchen : Icons.history,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(isActive ? "No active orders" : "No order history"),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isActive);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isActive) {
    final status = order['status'] ?? 'unknown';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final total = (order['totalAmount'] ?? 0.0).toStringAsFixed(2);

    // Format timestamp if available
    String timeStr = "Just now";
    if (order['orderDate'] != null) {
      // Handle Firestore Timestamp
      // final date = (order['orderDate'] as Timestamp).toDate();
      // timeStr = DateFormat('hh:mm a').format(date);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "#${order['orderId'].toString().substring(0, 5)}",
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
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Customer Info
            Text(
              "Customer: ${order['userName']}",
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              "Type: ${order['method']} • $timeStr",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Items List
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      "${item['quantity']}x ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(item['title'])),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              "Total: RM $total",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            // Action Buttons (Only for Active Orders)
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (status == 'paid') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus(order['id'], 'rejected'),
                        child: const Text(
                          "Reject",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => _updateStatus(order['id'], 'accepted'),
                        child: const Text(
                          "Accept Order",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                  if (status == 'accepted')
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () => _updateStatus(order['id'], 'ready'),
                        child: const Text(
                          "Mark Ready for Pickup",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (status == 'ready')
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        onPressed:
                            () => _updateStatus(order['id'], 'completed'),
                        child: const Text(
                          "Complete Order",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateStatus(String orderId, String newStatus) {
    context.read<MerchantOrderBloc>().add(
      UpdateOrderStatus(orderId, newStatus),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
