import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_state.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_event.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';
import 'models/delivery_info.dart';
import 'package:uniwaste/services/payment_service.dart';
import 'package:uniwaste/screens/marketplace/order_tracking/order_status_screen.dart';
import 'package:uniwaste/screens/profile/address_book_screen.dart';
import 'package:uniwaste/services/activity_share_helper.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryInfo _deliveryInfo = DeliveryInfo();
  bool _isProcessing = false;
  bool isDelivery = true;

  double _merchantDeliveryFee = 3.00;
  String _merchantName = "Merchant";
  bool _isLoadingFee = true;

  DocumentSnapshot? _selectedVoucherDoc;
  double _voucherDiscount = 0.0;

  final Color bgCream = const Color(0xFFF1F3E0);
  final Color sageGreen = const Color(0xFFD2DCB6);
  final Color accentGreen = const Color(0xFFA1BC98);
  final Color darkGreen = const Color(0xFF778873);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists && mounted) {
          final data = userDoc.data()!;
          setState(() {
            _deliveryInfo = DeliveryInfo(
              name: data['name'] ?? user.displayName ?? "Student",
              phone: data['phone'] ?? "",
              address: data['address'] ?? "Please select an address",
            );
          });
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
    }

    try {
      final state = context.read<CartBloc>().state;
      if (state is CartLoaded && state.items.isNotEmpty) {
        final merchantId = state.items.first.merchantId;
        if (merchantId != null && merchantId.isNotEmpty) {
          final doc =
              await FirebaseFirestore.instance
                  .collection('merchants')
                  .doc(merchantId)
                  .get();
          if (doc.exists && mounted) {
            setState(() {
              _merchantDeliveryFee =
                  (doc.data()?['deliveryFee'] ?? 3.00).toDouble();
              _merchantName = doc.data()?['name'] ?? "Merchant";
              _isLoadingFee = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingFee = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFee = false);
    }
  }

  void _showVoucherSelector() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select a Voucher",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('vouchers')
                          .where('isUsed', isEqualTo: false)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                      return const Center(
                        child: Text("No available vouchers."),
                      );

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final double value = (data['value'] ?? 0).toDouble();
                        final String title = data['title'] ?? 'Voucher';

                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.confirmation_number,
                              color: Colors.orange,
                            ),
                            title: Text(title),
                            subtitle: Text(
                              "Save RM ${value.toStringAsFixed(2)}",
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkGreen,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedVoucherDoc = docs[index];
                                  _voucherDiscount = value;
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Applied: $title"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text("Apply"),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePayment(
    List<CartItemModel> items,
    double amountToPay,
  ) async {
    setState(() => _isProcessing = true);

    final success = await PaymentService.instance.makePayment(
      context,
      amountToPay,
    );

    if (success) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final orderId = DateTime.now().millisecondsSinceEpoch.toString();
        // Simulate a Transaction ID
        final transactionId = "TXN-${DateTime.now().microsecondsSinceEpoch}";

        final String merchantId =
            items.isNotEmpty ? (items.first.merchantId ?? '') : '';

        if (merchantId.isEmpty) {
          setState(() => _isProcessing = false);
          return;
        }

        try {
          // 1. Inventory Sync
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            List<DocumentSnapshot> itemSnapshots = [];
            for (var item in items) {
              DocumentReference ref = FirebaseFirestore.instance
                  .collection('merchants')
                  .doc(merchantId)
                  .collection('items')
                  .doc(item.id);
              itemSnapshots.add(await transaction.get(ref));
            }

            for (int i = 0; i < items.length; i++) {
              var snapshot = itemSnapshots[i];
              var item = items[i];
              if (snapshot.exists) {
                var currentQty = snapshot.get('quantity');
                int qtyInt =
                    (currentQty is int)
                        ? currentQty
                        : int.tryParse(currentQty.toString()) ?? 0;
                int newQty = qtyInt - item.quantity;
                if (newQty < 0) newQty = 0;
                transaction.update(snapshot.reference, {
                  'quantity': newQty,
                  'isAvailable': newQty > 0,
                });
              }
            }
          });

          // 2. Create Order Data
          final orderData = {
            'orderId': orderId,
            'userId': user.uid,
            'userName':
                _deliveryInfo.name.isNotEmpty
                    ? _deliveryInfo.name
                    : (user.displayName ?? "Student"),
            'userEmail': user.email ?? "",
            'userPhone': _deliveryInfo.phone,
            'totalAmount': amountToPay,
            'deliveryFee': isDelivery ? _merchantDeliveryFee : 0.0,
            'voucherDiscount': _voucherDiscount,
            'status': 'pending',

            // PAYMENT DETAILS
            'paymentStatus': 'paid',
            'transactionId': transactionId,
            'paymentMethod': 'Stripe',

            'orderDate': FieldValue.serverTimestamp(),
            'merchantId': merchantId,
            'merchantName': _merchantName,
            'shippingAddress':
                isDelivery ? _deliveryInfo.address : "Self Pick-Up",
            'method': isDelivery ? 'Delivery' : 'Pick Up',
            'items':
                items
                    .map(
                      (i) => {
                        'id': i.id,
                        'name': i.name,
                        'price': i.price,
                        'quantity': i.quantity,
                        'imagePath': i.imagePath,
                      },
                    )
                    .toList(),
          };

          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .set(orderData);
          await FirebaseFirestore.instance
              .collection('merchants')
              .doc(merchantId)
              .collection('orders')
              .doc(orderId)
              .set(orderData);

          if (_selectedVoucherDoc != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('vouchers')
                .doc(_selectedVoucherDoc!.id)
                .update({'isUsed': true});
          }

          if (mounted) {
            final int pointsEarned = (amountToPay * 10).toInt();
            String itemSummary = items.first.name;
            if (items.length > 1)
              itemSummary += " and ${items.length - 1} others";

            await ActivityShareHelper.recordAndMaybeShare(
              context: context,
              userId: user.uid,
              userDisplayName: user.displayName,
              title: "ordered $itemSummary",
              description: "received food from $_merchantName.",
              points: pointsEarned,
              type: 'merchant_order',
              createActivity: true,
            );
          }

          // 3. Navigation
          if (mounted) {
            context.read<CartBloc>().add(ClearCart());
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => OrderStatusScreen(orderId: orderId),
              ),
              (Route<dynamic> route) => route.isFirst,
            );
          }
        } catch (e) {
          print("❌ Order Failed: $e");
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Order failed: $e")));
        }
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgCream,
        elevation: 0,
        iconTheme: IconThemeData(color: darkGreen),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty) {
            return const Center(child: Text("No items"));
          }

          final checkoutItems = state.items.where((i) => i.isSelected).toList();
          final subtotal = checkoutItems.fold(
            0.0,
            (sum, i) => sum + (i.price * i.quantity),
          );
          final deliveryFee = isDelivery ? _merchantDeliveryFee : 0.00;
          double total = (subtotal + deliveryFee) - _voucherDiscount;
          if (total < 0) total = 0;

          return Stack(
            children: [
              Positioned.fill(
                bottom: 100,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildOptionButton(
                              "Delivery",
                              isActive: isDelivery,
                              onTap: () => setState(() => isDelivery = true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildOptionButton(
                              "Pick Up",
                              isActive: !isDelivery,
                              onTap: () => setState(() => isDelivery = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (isDelivery) ...[
                        Text(
                          "Delivery Address",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: darkGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.location_on, color: darkGreen),
                            title: Text(
                              _deliveryInfo.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(_deliveryInfo.address),
                            trailing: TextButton(
                              child: Text(
                                "Change",
                                style: TextStyle(color: accentGreen),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const AddressBookScreen(
                                          selectMode: true,
                                        ),
                                  ),
                                );
                                if (result != null && result is String)
                                  setState(
                                    () => _deliveryInfo.address = result,
                                  );
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          "Pick Up Location",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: darkGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.store, color: darkGreen, size: 30),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Collect at $_merchantName Counter when 'Ready'",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Text(
                        "Rewards & Vouchers",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              title: Text(
                                _selectedVoucherDoc == null
                                    ? "Select a voucher"
                                    : "Voucher Applied",
                                style: TextStyle(
                                  color:
                                      _selectedVoucherDoc == null
                                          ? Colors.black
                                          : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle:
                                  _selectedVoucherDoc == null
                                      ? const Text(
                                        "Tap to see available rewards",
                                      )
                                      : Text(
                                        "- RM ${_voucherDiscount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.green,
                                        ),
                                      ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: _showVoucherSelector,
                            ),
                            if (_selectedVoucherDoc != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedVoucherDoc = null;
                                    _voucherDiscount = 0.0;
                                  });
                                },
                                child: const Text(
                                  "Remove Voucher",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "Order Summary",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ...checkoutItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${item.quantity}x  ${item.name}"),
                                    Text(
                                      "RM ${(item.price * item.quantity).toStringAsFixed(2)}",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(),
                            _buildCostRow(
                              "Subtotal",
                              "RM ${subtotal.toStringAsFixed(2)}",
                            ),
                            _buildCostRow(
                              "Delivery Fee",
                              isDelivery
                                  ? (_isLoadingFee
                                      ? "..."
                                      : "RM ${_merchantDeliveryFee.toStringAsFixed(2)}")
                                  : "Free",
                            ),

                            if (_voucherDiscount > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Voucher Discount",
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      "- RM ${_voucherDiscount.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const Divider(),
                            _buildCostRow(
                              "Total",
                              "RM ${total.toStringAsFixed(2)}",
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing || _isLoadingFee
                              ? null
                              : () {
                                // 1. Check Minimum Amount (Stripe Rule: > RM 2.00)
                                if (total < 2.00) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Minimum order amount for payment is RM 2.00",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                // 2. Proceed if Valid
                                _handlePayment(checkoutItems, total);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isProcessing
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Pay RM ${total.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOptionButton(
    String text, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? sageGreen : Colors.white,
          border: Border.all(
            color: isActive ? darkGreen : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? darkGreen : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? darkGreen : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
