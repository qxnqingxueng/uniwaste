import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; 
import 'package:user_repository/user_repository.dart'; 

import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/p2p/create_listing_screen.dart'; 
import 'package:uniwaste/services/chat_service.dart';
import 'package:uniwaste/screens/social/chat_detail_screen.dart';
import 'package:uniwaste/services/activity_share_helper.dart';
import 'package:uniwaste/screens/p2p/product_detail_screen.dart';
import 'package:uniwaste/widgets/animated_check.dart';

class P2PStudentPage extends StatefulWidget {
  const P2PStudentPage({super.key});

  @override
  State<P2PStudentPage> createState() => _P2PStudentPageState();
}

class _P2PStudentPageState extends State<P2PStudentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- PRE-LOAD LOGIC ---
  Future<Map<String, MemoryImage?>> _preloadDonorImages(
    BuildContext context, 
    List<QueryDocumentSnapshot> listings
  ) async {
    final Set<String> donorIds = {};
    final Map<String, MemoryImage?> imageMap = {};

    // 1. Collect unique Donor IDs
    for (var doc in listings) {
      final data = doc.data() as Map<String, dynamic>;
      final String? did = data['donor_id'];
      if (did != null && did.isNotEmpty) {
        donorIds.add(did);
      }
    }

    // 2. Fetch all donor profiles in parallel
    await Future.wait(donorIds.map((id) async {
      try {
        final doc = await _db.collection('users').doc(id).get();
        if (doc.exists) {
          final userData = doc.data();
          final String? base64Str = userData?['photoBase64'];

          if (base64Str != null && base64Str.isNotEmpty) {
            try {
              final Uint8List bytes = base64Decode(base64Str);
              final provider = MemoryImage(bytes);
              
              // 3. Precache the image so it renders instantly
              if (context.mounted) {
                await precacheImage(provider, context);
              }
              imageMap[id] = provider;
            } catch (e) {
              debugPrint("Error decoding image for $id: $e");
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching donor $id: $e");
      }
    }));

    return imageMap;
  }

  // --- CLAIM LOGIC ---
  Future<void> _performClaim(
    String docId,
    String currentUserId,
    String currentUserName,
    String donorId,
    String donorName,
    Map<String, dynamic> itemData,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await _db.collection('food_listings').doc(docId).update({
        'status': 'reserved',
        'claimed_by': currentUserId,
        'claimed_at': FieldValue.serverTimestamp(),
      });

      final bool isFree = itemData['is_free'] ?? true;
      final double price = (itemData['price'] ?? 0).toDouble();
      final String itemName = itemData['description'] ?? 'Food item';

      final chatService = ChatService();
      await chatService.createChatAndSendCard(
        listingId: docId,
        donorId: donorId,
        claimerId: currentUserId,
        donorName: donorName,
        claimerName: currentUserName,
        itemName: itemName,
        itemDescription: itemData['description'] ?? '',
        isFree: isFree,
        price: price,
      );

      if (mounted) {
        Navigator.pop(context); // Close Loader
        Navigator.pop(context); // Close Detail Screen
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const AnimatedCheck(size: 80), 
                const SizedBox(height: 20),
                const Text("Claim Successful!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Check your "My Claims" tab.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(color: Color(0xFF6B8E23))),
              )
            ],
          ),
        );

        _tabController.animateTo(1); // Auto-switch to "My Claims"
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- SHARE LOGIC ---
  Future<void> _shareItem(Map<String, dynamic> data, String docId, String userId, String userName) async {
      final bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Share to Feed?"),
          content: const Text("Do you want to share this activity so others can see your impact?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Not now", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Share", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B8E23))),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      await ActivityShareHelper.shareToFeedDirectly(
        userId: userId,
        userDisplayName: userName,
        title: 'You claimed ${data['description']}',
        description: 'You received food from ${data['donor_name']}.',
        points: 50,
        type: 'p2p_free',
        extra: {},
      );
      
      if(mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const AnimatedCheck(size: 80),
                const SizedBox(height: 20),
                const Text("Shared to Feed!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Your community can now see your impact.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(color: Color(0xFF6B8E23))),
              )
            ],
          ),
        );
      }
  }

  // --- CHAT LOGIC ---
  Future<void> _openChat(Map<String, dynamic> data, String userId, String userName) async {
    final chatService = ChatService();
    final chatId = await chatService.getOrCreateChat(
      userAId: userId, userBId: data['donor_id'], currentUserName: userName, otherUserName: data['donor_name']
    );
    if(mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chatId, currentUserId: userId, otherUserId: data['donor_id'], otherUserName: data['donor_name'], itemName: data['description'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Student Food Exchange"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(119, 136, 115, 1.0),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(119, 136, 115, 1.0),
          tabs: const [
            Tab(text: "Available"),
            Tab(text: "My Claims"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingScreen()),
          );
        },
        backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0), 
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableGrid(),
          _buildMyClaimsList(),
        ],
      ),
    );
  }

  Widget _buildAvailableGrid() {
    final currentUser = context.select((AuthenticationBloc bloc) => bloc.state.user);

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('food_listings')
          .where('status', isEqualTo: 'available')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];

        final validDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp? expiryTs = data['expiry_date'] as Timestamp?;
          if (expiryTs != null && expiryTs.toDate().isBefore(DateTime.now())) {
            return false;
          }
          return true;
        }).toList();
        
        if (validDocs.isEmpty) {
          return const Center(child: Text("No items available"));
        }

        // --- NEW: Wait for ALL images to load before showing grid ---
        return FutureBuilder<Map<String, MemoryImage?>>(
          future: _preloadDonorImages(context, validDocs),
          builder: (context, imageSnapshot) {
            
            // SHOW LOADER UNTIL IMAGES ARE READY
            if (imageSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final imageMap = imageSnapshot.data ?? {};

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: validDocs.length, 
              itemBuilder: (context, index) {
                final doc = validDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final donorId = data['donor_id'] ?? '';

                // Pass the pre-loaded image
                return _buildGridCard(data, docId, currentUser, imageMap[donorId]);
              },
            );
          },
        );
      },
    );
  }

Widget _buildGridCard(
    Map<String, dynamic> data, 
    String docId, 
    MyUser? currentUser,
    MemoryImage? preloadedImage, // This image is already loaded in memory
  ) {
    Uint8List? imageBytes;
    if (data['image_blob'] != null && data['image_blob'] is Blob) {
      imageBytes = (data['image_blob'] as Blob).bytes;
    }

    final bool isFree = data['is_free'] ?? true;
    final double price = (data['price'] ?? 0).toDouble();
    final String donorName = data['donor_name'] ?? 'User';
    
    final Color chatAvatarColor = const Color.fromRGBO(210, 220, 182, 1);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              data: data,
              docId: docId,
              currentUser: currentUser,
              onClaim: _performClaim,
              // ✅ PASS THE IMAGE HERE
              preloadedDonorImage: preloadedImage,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: imageBytes != null
                      ? Image.memory(imageBytes, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['description'] ?? 'Item',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: chatAvatarColor,
                        backgroundImage: preloadedImage,
                        child: preloadedImage == null
                          ? Text(
                              donorName.isNotEmpty ? donorName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 8, color: Colors.black87),
                            )
                          : null,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          donorName,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        isFree ? "Free" : "RM ${price.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isFree ? const Color(0xFF6B8E23) : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyClaimsList() {
    final currentUser = context.select((AuthenticationBloc bloc) => bloc.state.user);
    final uid = currentUser?.userId ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('food_listings')
          .where('claimed_by', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("You haven't claimed anything yet."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['description'] ?? ''),
                subtitle: Text("From: ${data['donor_name']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.chat), onPressed: () => _openChat(data, uid, currentUser?.name ?? '')),
                    IconButton(icon: const Icon(Icons.share), onPressed: () => _shareItem(data, docs[index].id, uid, currentUser?.name ?? '')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}