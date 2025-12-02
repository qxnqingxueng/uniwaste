import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; 
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/p2p/create_listing_screen.dart'; 

class P2PStudentPage extends StatefulWidget {
  const P2PStudentPage({super.key});

  @override
  State<P2PStudentPage> createState() => _P2PStudentPageState();
}

class _P2PStudentPageState extends State<P2PStudentPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Logic to Claim an Item ---
  Future<void> _claimItem(String docId, String currentUserId) async {
    try {
      await _db.collection('food_listings').doc(docId).update({
        'status': 'reserved',
        'claimed_by': currentUserId,
        'claimed_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item claimed! Chat started (placeholder).')),
        );
      }
      // TODO: Navigate to Chat Screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select((AuthenticationBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Food Exchange"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // FAB to Navigate to Create Listing Page
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingScreen()),
          );
        },
        backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Donate / Sell", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('food_listings')
            .where('status', isEqualTo: 'available') // Only show available items
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No food listings available right now.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              
              // 1. Filter Expired Items Manually (Safety Check)
              final Timestamp? expiryTs = data['expiry_date'] as Timestamp?;
              if (expiryTs != null) {
                if (expiryTs.toDate().isBefore(DateTime.now())) {
                  return const SizedBox.shrink(); // Hide expired item
                }
              }

              // 2. Decode Blob Image
              Uint8List? imageBytes;
              if (data['image_blob'] != null && data['image_blob'] is Blob) {
                imageBytes = (data['image_blob'] as Blob).bytes;
              }

              final bool isFree = data['is_free'] ?? true;
              final double price = (data['price'] ?? 0).toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Image Header ---
                    SizedBox(
                      height: 180,
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                    ),

                    // --- Content Body ---
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['description'] ?? 'No Description',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFree ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isFree ? 'FREE' : 'RM ${price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isFree ? Colors.green.shade800 : Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                "Donor: ${data['donor_name'] ?? 'Unknown'}",
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (expiryTs != null)
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Text(
                                  "Expires: ${DateFormat('MMM d, h:mm a').format(expiryTs.toDate())}",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // --- Action Buttons ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (currentUser?.userId == data['donor_id']) 
                                ? null // Disable if it's your own post
                                : () => _claimItem(docId, currentUser?.userId ?? ''),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (currentUser?.userId == data['donor_id']) 
                                  ? Colors.grey 
                                  : const Color.fromRGBO(119, 136, 115, 1.0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                (currentUser?.userId == data['donor_id']) 
                                  ? "Your Listing" 
                                  : "Claim This Item",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}