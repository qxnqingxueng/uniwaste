import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VoucherScreen extends StatelessWidget {
  const VoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final vouchersQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('vouchers')
        .orderBy('expiry');               // <-- No index needed

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA1BC98),
        elevation: 0,
        title: const Text(
          "My Vouchers",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: vouchersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading vouchers: ${snapshot.error}"),
            );
          }

          final rawDocs = snapshot.data?.docs ?? [];

          // 🔥 Filter out used vouchers (instead of .where in Firestore)
          final docs = rawDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isUsed'] != true;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No vouchers yet.\nEarn more points to unlock rewards!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final voucher = docs[index].data() as Map<String, dynamic>;

              final title = voucher['title'] ?? 'Voucher';
              final brand = voucher['brand'] ?? 'UniWaste';
              final expiry = voucher['expiry'] as Timestamp;

              final expiryFormatted =
                  DateFormat('dd MMM yyyy').format(expiry.toDate());

              return _buildVoucherCard(
                title: title,
                brand: brand,
                expiry: "Valid until $expiryFormatted",
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVoucherCard({
    required String title,
    required String brand,
    required String expiry,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA1BC98),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            brand,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            expiry,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
