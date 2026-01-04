import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_repository/user_repository.dart';
import 'package:uniwaste/screens/social/friend_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final MyUser? currentUser;
  final Function(String, String, String, String, String, Map<String, dynamic>)
      onClaim;

  // ✅ Pre-cached image from listing page
  final MemoryImage? preloadedDonorImage;

  const ProductDetailScreen({
    super.key,
    required this.data,
    required this.docId,
    required this.currentUser,
    required this.onClaim,
    this.preloadedDonorImage,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = true;

  // ✅ MUST be in State, not Widget
  String _donorId = '';

  String _donorEmail = '';
  String? _donorAvatarBase64;
  MemoryImage? _donorImageProvider;

  final Color _chatAvatarColor = const Color.fromRGBO(210, 220, 182, 1);

  @override
  void initState() {
    super.initState();

    // ✅ Show UI immediately if image is preloaded
    if (widget.preloadedDonorImage != null) {
      _donorImageProvider = widget.preloadedDonorImage;
      _isLoading = false;
    }

    _loadDonorProfile();
  }

  Future<void> _loadDonorProfile() async {
    final String donorId = (widget.data['donor_id'] ?? '') as String;
    _donorId = donorId;

    if (donorId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(donorId)
            .get();

        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>;

          if (mounted) {
            setState(() {
              _donorEmail = (userData['email'] ?? '') as String;
              _donorAvatarBase64 = userData['photoBase64'] as String?;
            });
          }

          if (_donorImageProvider == null &&
              _donorAvatarBase64 != null &&
              _donorAvatarBase64!.isNotEmpty) {
            try {
              final Uint8List bytes = base64Decode(_donorAvatarBase64!);
              final provider = MemoryImage(bytes);

              if (mounted) {
                await precacheImage(provider, context);
                setState(() {
                  _donorImageProvider = provider;
                });
              }
            } catch (e) {
              debugPrint("Error decoding donor profile image: $e");
            }
          }
        }
      } catch (e) {
        debugPrint("Error loading donor profile: $e");
      }
    }

    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Uint8List? imageBytes;
    if (widget.data['image_blob'] != null && widget.data['image_blob'] is Blob) {
      imageBytes = (widget.data['image_blob'] as Blob).bytes;
    }

    final bool isFree = (widget.data['is_free'] ?? true) as bool;
    final double price = (widget.data['price'] ?? 0).toDouble();
    final String donorName = (widget.data['donor_name'] ?? 'Unknown') as String;
    final Timestamp? expiryTs = widget.data['expiry_date'] as Timestamp?;
    final bool isMyListing = widget.currentUser?.userId == widget.data['donor_id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image
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
                        Row(
                          children: [
                            Text(
                              isFree ? "FREE" : "RM ${price.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isFree
                                    ? const Color(0xFF6B8E23)
                                    : Colors.black,
                              ),
                            ),
                            if (!isFree)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, top: 4),
                                child: Text(
                                  "approx.",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (widget.data['description'] ?? 'No Description') as String,
                          style: const TextStyle(fontSize: 18, height: 1.4),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // --- DONOR INFO ---
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _chatAvatarColor,
                              backgroundImage: _donorImageProvider,
                              child: _donorImageProvider == null
                                  ? Text(
                                      donorName.isNotEmpty
                                          ? donorName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(color: Colors.black87),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  donorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  "Active recently",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            OutlinedButton(
                              onPressed: _donorId.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FriendProfileScreen(
                                            friendUserId: _donorId,
                                            name: donorName,
                                            email: _donorEmail.isEmpty
                                                ? 'Loading...'
                                                : _donorEmail,
                                            avatarBase64: _donorAvatarBase64,
                                          ),
                                        ),
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                shape: const StadiumBorder(),
                              ),
                              child: const Text("View Profile"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

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
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
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

          // --- BOTTOM BUTTON ---
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isMyListing
                      ? null
                      : () {
                          widget.onClaim(
                            widget.docId,
                            widget.currentUser?.userId ?? '',
                            widget.currentUser?.name ?? 'Student',
                            (widget.data['donor_id'] ?? '') as String,
                            (widget.data['donor_name'] ?? 'Unknown') as String,
                            widget.data,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    isMyListing ? "Your Listing" : "I Want This!",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
