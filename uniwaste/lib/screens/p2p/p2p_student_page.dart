import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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

class _P2PStudentPageState extends State<P2PStudentPage>
    with SingleTickerProviderStateMixin {
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

  // --- PRE-LOAD DONOR IMAGES ---
  Future<Map<String, MemoryImage?>> _preloadDonorImages(
    BuildContext context,
    List<QueryDocumentSnapshot> listings,
  ) async {
    final Set<String> donorIds = {};
    final Map<String, MemoryImage?> imageMap = {};

    for (var doc in listings) {
      final data = doc.data() as Map<String, dynamic>;
      final String? did = data['donor_id'];
      if (did != null && did.isNotEmpty) {
        donorIds.add(did);
      }
    }

    await Future.wait(
      donorIds.map((id) async {
        try {
          final doc = await _db.collection('users').doc(id).get();
          if (doc.exists) {
            final userData = doc.data();
            final String? base64Str = userData?['photoBase64'];

            if (base64Str != null && base64Str.isNotEmpty) {
              try {
                final Uint8List bytes = base64Decode(base64Str);
                final provider = MemoryImage(bytes);
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
      }),
    );

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
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
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
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    AnimatedCheck(size: 80),
                    SizedBox(height: 20),
                    Text(
                      "Claim Successful!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check your "My Claims" tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Color(0xFF6B8E23)),
                    ),
                  ),
                ],
              ),
        );

        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- SHARE LOGIC ---
  Future<void> _shareItem(
    Map<String, dynamic> data,
    String docId,
    String userId,
    String userName,
  ) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text("Share to Feed?"),
                content: const Text(
                  "Do you want to share this activity so others can see your impact?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      "Not now",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Share",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B8E23),
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

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

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10),
                  AnimatedCheck(size: 80),
                  SizedBox(height: 20),
                  Text(
                    "Shared to Feed!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your community can now see your impact.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Color(0xFF6B8E23)),
                  ),
                ),
              ],
            ),
      );
    }
  }

  // --- CHAT LOGIC ---
  Future<void> _openChat(
    Map<String, dynamic> data,
    String userId,
    String userName,
  ) async {
    final chatService = ChatService();
    final chatId = await chatService.getOrCreateChat(
      userAId: userId,
      userBId: data['donor_id'],
      currentUserName: userName,
      otherUserName: data['donor_name'],
    );
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChatDetailScreen(
                chatId: chatId,
                currentUserId: userId,
                otherUserId: data['donor_id'],
                otherUserName: data['donor_name'],
                itemName: data['description'],
              ),
        ),
      );
    }
  }

  // --- REPUTATION SYSTEM LOGIC ---
  Future<void> _submitRating(
    String donorId,
    double stars,
    String listingId,
  ) async {
    final double ratingValue = stars * 20.0;
    final donorRef = _db.collection('users').doc(donorId);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(donorRef);
        if (!snapshot.exists) return;

        final double currentScore =
            (snapshot.data()?['reputationScore'] ?? 100).toDouble();
        final int currentCount = (snapshot.data()?['ratingCount'] ?? 0).toInt();

        final double newScore =
            ((currentScore * currentCount) + ratingValue) / (currentCount + 1);

        transaction.update(donorRef, {
          'reputationScore': newScore,
          'ratingCount': currentCount + 1,
        });

        transaction.update(_db.collection('food_listings').doc(listingId), {
          'is_rated': true,
        });
      });

      if (mounted) {
        Navigator.pop(context); // Close Rating Dialog

        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    AnimatedCheck(size: 80),
                    SizedBox(height: 20),
                    Text(
                      "Review Submitted!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Color(0xFF6B8E23)),
                    ),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint("Error rating user: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  // --- REPORT LOGIC ---
  Future<void> _submitReport(
    String donorId,
    String reason,
    String listingId,
    Uint8List? proofBytes,
  ) async {
    if (reason.trim().isEmpty) return;

    final String? reporterId =
        context.read<AuthenticationBloc>().state.user?.userId;
    if (reporterId == null) return;

    try {
      // 1. CHECK FOR DUPLICATES
      final existingReports =
          await _db
              .collection('reports')
              .where('listing_id', isEqualTo: listingId)
              .where('reporter_id', isEqualTo: reporterId)
              .get();

      if (existingReports.docs.isNotEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You have already reported this item."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. PREPARE DATA
      final Map<String, dynamic> reportData = {
        'reported_user': donorId,
        'reason': reason,
        'listing_id': listingId,
        'timestamp': FieldValue.serverTimestamp(),
        'reporter_id': reporterId,
      };

      if (proofBytes != null) {
        reportData['report_proof_blob'] = Blob(proofBytes);
      }

      // 3. RUN TRANSACTION
      await _db.runTransaction((transaction) async {
        final newReportRef = _db.collection('reports').doc();
        transaction.set(newReportRef, reportData);

        final userRef = _db.collection('users').doc(donorId);
        transaction.update(userRef, {'reportCount': FieldValue.increment(1)});

        final listingRef = _db.collection('food_listings').doc(listingId);
        transaction.update(listingRef, {'is_reported_by_claimer': true});
      });

      if (mounted) {
        Navigator.pop(context); // Close Report Dialog

        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    AnimatedCheck(size: 80),
                    SizedBox(height: 20),
                    Text(
                      "Report Submitted!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Thank you for helping keep the community safe.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Color(0xFF6B8E23)),
                    ),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint("Error reporting user: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showRatingDialog(String donorId, String listingId) {
    double rating = 5.0;
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text("Rate Donor"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("How was the food quality and transaction?"),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() => rating = index + 1.0);
                          },
                        );
                      }),
                    ),
                    Text(
                      "${rating.toInt()} / 5 Stars",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => _submitRating(donorId, rating, listingId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B8E23),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Submit"),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showReportDialog(String donorId, String listingId) {
    final reasonController = TextEditingController();
    Uint8List? proofImage;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text("Report Issue"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Please describe the issue and upload proof."),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: "Enter reason...",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () async {
                        // Added maxWidth and imageQuality to reduce size < 1MB
                        final XFile? image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800, // Resize to max 800px width
                          imageQuality: 50, // Compress quality to 50%
                        );

                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() => proofImage = bytes);
                        }
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child:
                            proofImage == null
                                ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Colors.grey),
                                    Text(
                                      "Upload Proof Image",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    proofImage!,
                                    fit: BoxFit.cover,
                                    width: double.maxFinite,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      if (proofImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Proof image is required."),
                          ),
                        );
                        return;
                      }
                      _submitReport(
                        donorId,
                        reasonController.text,
                        listingId,
                        proofImage,
                      );
                    },
                    child: const Text(
                      "Report",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Student Food Exchange"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(119, 136, 115, 1.0),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(119, 136, 115, 1.0),
          tabs: const [Tab(text: "Available"), Tab(text: "My Claims")],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateListingScreen(),
            ),
          );
        },
        backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAvailableGrid(), _buildMyClaimsList()],
      ),
    );
  }

  Widget _buildAvailableGrid() {
    final currentUser = context.select(
      (AuthenticationBloc bloc) => bloc.state.user,
    );

    return StreamBuilder<QuerySnapshot>(
      stream:
          _db
              .collection('food_listings')
              .where('status', isEqualTo: 'available')
              .orderBy('created_at', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];

        final validDocs =
            allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? expiryTs = data['expiry_date'] as Timestamp?;
              if (expiryTs != null &&
                  expiryTs.toDate().isBefore(DateTime.now())) {
                return false;
              }
              return true;
            }).toList();

        if (validDocs.isEmpty) {
          return const Center(child: Text("No items available"));
        }

        return FutureBuilder<Map<String, MemoryImage?>>(
          future: _preloadDonorImages(context, validDocs),
          builder: (context, imageSnapshot) {
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

                return _buildGridCard(
                  data,
                  docId,
                  currentUser,
                  imageMap[donorId],
                );
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
    MemoryImage? preloadedImage,
  ) {
    Uint8List? imageBytes;
    if (data['image_blob'] != null && data['image_blob'] is Blob) {
      imageBytes = (data['image_blob'] as Blob).bytes;
    }

    final bool isFree = data['is_free'] ?? true;
    final double price = (data['price'] ?? 0).toDouble();
    final String donorName = data['donor_name'] ?? 'User';

    const Color chatAvatarColor = Color.fromRGBO(210, 220, 182, 1);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProductDetailScreen(
                  data: data,
                  docId: docId,
                  currentUser: currentUser,
                  onClaim: _performClaim,
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child:
                      imageBytes != null
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
                        child:
                            preloadedImage == null
                                ? Text(
                                  donorName.isNotEmpty
                                      ? donorName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.black87,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          donorName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        isFree ? "Free" : "RM ${price.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              isFree ? const Color(0xFF6B8E23) : Colors.black,
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
    final currentUser = context.select(
      (AuthenticationBloc bloc) => bloc.state.user,
    );
    final uid = currentUser?.userId ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream:
          _db
              .collection('food_listings')
              .where('claimed_by', isEqualTo: uid)
              .orderBy('created_at', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("You haven't claimed anything yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final donorId = data['donor_id'] ?? '';
            final bool isRated = data['is_rated'] ?? false;
            final bool isReported = data['is_reported_by_claimer'] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      data['description'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("From: ${data['donor_name']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat),
                          onPressed:
                              () =>
                                  _openChat(data, uid, currentUser?.name ?? ''),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        if (!isRated)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              label: const Text("Rate"),
                              onPressed:
                                  () => _showRatingDialog(
                                    donorId,
                                    docs[index].id,
                                  ),
                            ),
                          )
                        else
                          const Expanded(
                            child: Center(
                              child: Text(
                                "Rated ✅",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),

                        const SizedBox(width: 10),

                        if (!isReported)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.flag,
                                size: 16,
                                color: Colors.red,
                              ),
                              label: const Text(
                                "Report",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed:
                                  () => _showReportDialog(
                                    donorId,
                                    docs[index].id,
                                  ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: null, // Disabled
                              icon: const Icon(
                                Icons.flag,
                                size: 16,
                                color: Colors.grey,
                              ),
                              label: const Text(
                                "Reported",
                                style: TextStyle(color: Colors.grey),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
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
    );
  }
}
