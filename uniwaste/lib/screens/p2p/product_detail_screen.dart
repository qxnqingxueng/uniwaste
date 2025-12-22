import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_repository/user_repository.dart'; // Import for MyUser

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final MyUser? currentUser;
  final Function(String, String, String, String, String, Map<String, dynamic>) onClaim;

  const ProductDetailScreen({
    super.key,
    required this.data,
    required this.docId,
    required this.currentUser,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Process Image
    Uint8List? imageBytes;
    if (data['image_blob'] != null && data['image_blob'] is Blob) {
      imageBytes = (data['image_blob'] as Blob).bytes;
    }

    final bool isFree = data['is_free'] ?? true;
    final double price = (data['price'] ?? 0).toDouble();
    final String donorName = data['donor_name'] ?? 'Unknown';
    final Timestamp? expiryTs = data['expiry_date'] as Timestamp?;
    final bool isMyListing = currentUser?.userId == data['donor_id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
           IconButton(
             icon: const Icon(Icons.share, color: Colors.black),
             onPressed: () {}, // Optional share button
           ),
        ],
      ),
      extendBodyBehindAppBar: true, // Image goes behind App Bar
      body: Column(
        children: [
          // --- SCROLLABLE CONTENT ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big Image
                  Container(
                    width: double.infinity,
                    height: 350,
                    color: Colors.grey.shade200,
                    child: imageBytes != null
                        ? Image.memory(imageBytes, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price / Free Tag
                        Row(
                          children: [
                            Text(
                              isFree ? "FREE" : "RM ${price.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isFree ? const Color(0xFF6B8E23) : Colors.black,
                              ),
                            ),
                            if (!isFree)
                               Padding(
                                padding: const EdgeInsets.only(left: 8.0, top: 4),
                                child: Text("approx.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                               ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title / Description
                        Text(
                          data['description'] ?? 'No Description',
                          style: const TextStyle(fontSize: 18, height: 1.4),
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Donor Info
                        Row(
                          children: [
                             CircleAvatar(
                               backgroundColor: Colors.grey.shade300,
                               child: Text(donorName[0].toUpperCase()),
                             ),
                             const SizedBox(width: 12),
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(donorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                 const Text("Active 2h ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
                               ],
                             ),
                             const Spacer(),
                             OutlinedButton(
                               onPressed: (){}, 
                               style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                               child: const Text("View Profile"),
                             )
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Expiry Info
                         if (expiryTs != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Expires: ${DateFormat('MMM d, h:mm a').format(expiryTs.toDate())}",
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTTOM ACTION BAR ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isMyListing 
                    ? null 
                    : () {
                        // Trigger Claim Logic passed from parent
                        onClaim(
                          docId,
                          currentUser?.userId ?? '',
                          currentUser?.name ?? 'Student',
                          data['donor_id'] ?? '',
                          data['donor_name'] ?? 'Unknown',
                          data,
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text(
                    isMyListing ? "Your Listing" : "I Want This!",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}