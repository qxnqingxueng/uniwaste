import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uniwaste/services/chat_service.dart';
import 'package:uniwaste/screens/social/friend_profile_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String itemName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.itemName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  bool _isLoading = true;

  Map<String, dynamic>? _otherUserData;
  MemoryImage? _profileImageProvider;

  @override
  void initState() {
    super.initState();
    _loadProfileAndCache();
  }

  // Fetch & cache avatar/profile
  Future<void> _loadProfileAndCache() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (doc.exists) {
        _otherUserData = doc.data();

        final String? base64Photo = _otherUserData?['photoBase64'];
        if (base64Photo != null && base64Photo.isNotEmpty) {
          try {
            final Uint8List bytes = base64Decode(base64Photo);
            final image = MemoryImage(bytes);
            if (mounted) {
              await precacheImage(image, context);
            }
            _profileImageProvider = image;
          } catch (e) {
            debugPrint("Error decoding profile image: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Send a *friend request* from chat, using incoming/outgoingRequests.
  Future<void> _sendFriendRequestFromChat() async {
    try {
      final String currentUserId = widget.currentUserId;
      final String otherUserId = widget.otherUserId;

      final currentRef =
          FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final otherRef =
          FirebaseFirestore.instance.collection('users').doc(otherUserId);

      final currentSnap = await currentRef.get();
      final otherSnap = await otherRef.get();

      if (!currentSnap.exists || !otherSnap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      final currentData = currentSnap.data() as Map<String, dynamic>;
      final otherData = otherSnap.data() as Map<String, dynamic>;

      final String otherName =
          otherData['name'] ?? widget.otherUserName;

      final List<dynamic> currentFriends =
          (currentData['friends'] as List<dynamic>?) ?? [];
      final List<dynamic> currentOutgoing =
          (currentData['outgoingRequests'] as List<dynamic>?) ?? [];
      final List<dynamic> currentIncoming =
          (currentData['incomingRequests'] as List<dynamic>?) ?? [];

      final List<dynamic> otherFriends =
          (otherData['friends'] as List<dynamic>?) ?? [];
      final List<dynamic> otherOutgoing =
          (otherData['outgoingRequests'] as List<dynamic>?) ?? [];
      final List<dynamic> otherIncoming =
          (otherData['incomingRequests'] as List<dynamic>?) ?? [];

      // --- Guard conditions (same logic as Add Friend feature) ---

      if (currentFriends.contains(otherUserId) ||
          otherFriends.contains(currentUserId)) {
        // Already friends
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$otherName is already your friend')),
        );
        return;
      }

      if (currentOutgoing.contains(otherUserId)) {
        // Already sent
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request already sent to $otherName')),
        );
        return;
      }

      if (currentIncoming.contains(otherUserId)) {
        // They already requested you
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$otherName has already sent you a request. Check your friend requests.',
            ),
          ),
        );
        return;
      }

      if (otherIncoming.contains(currentUserId) ||
          otherOutgoing.contains(currentUserId)) {
        // Symmetry safety, but should be covered by above
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request is already pending with $otherName'),
          ),
        );
        return;
      }

      // --- Actually send the request ---
      await Future.wait([
        currentRef.update({
          'outgoingRequests': FieldValue.arrayUnion([otherUserId]),
        }),
        otherRef.update({
          'incomingRequests': FieldValue.arrayUnion([currentUserId]),
        }),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to $otherName')),
      );
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send friend request')),
      );
    }
  }

  /// Mini profile card – uses friends / incomingRequests / outgoingRequests arrays.
  void _showUserCard() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final String name = _otherUserData?['name'] ?? widget.otherUserName;
        final String gender =
            _otherUserData?['gender'] ?? 'Not Specified';
        final String ranking =
            _otherUserData?['ranking'] ?? '1st Eco-Warrior';
        final String email =
            _otherUserData?['email'] ?? 'Not Provided';
        final String? photoBase64 = _otherUserData?['photoBase64'];

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId);

        return StreamBuilder<DocumentSnapshot>(
          stream: userRef.snapshots(),
          builder: (context, snap) {
            bool isFriend = false;
            bool hasOutgoing = false;
            bool hasIncoming = false;

            if (snap.hasData && snap.data != null && snap.data!.exists) {
              final data =
                  snap.data!.data() as Map<String, dynamic>?;
              final List<dynamic> friends =
                  (data?['friends'] as List<dynamic>?) ?? [];
              final List<dynamic> outgoing =
                  (data?['outgoingRequests'] as List<dynamic>?) ?? [];
              final List<dynamic> incoming =
                  (data?['incomingRequests'] as List<dynamic>?) ?? [];

              isFriend = friends.contains(widget.otherUserId);
              hasOutgoing = outgoing.contains(widget.otherUserId);
              hasIncoming = incoming.contains(widget.otherUserId);
            }

            String buttonText;
            if (isFriend) {
              buttonText = 'Already in friends ✓';
            } else if (hasOutgoing) {
              buttonText = 'Request sent ✓';
            } else if (hasIncoming) {
              buttonText = 'Request received ✓';
            } else {
              buttonText = 'Add to friends';
            }

            final bool canTap =
                !isFriend && !hasOutgoing && !hasIncoming;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromRGBO(
                              119, 136, 115, 1.0),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImageProvider,
                        child: _profileImageProvider == null
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(210, 220, 182, 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ranking,
                        style: const TextStyle(
                          color: Color.fromRGBO(80, 95, 75, 1),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 5),
                    _buildInfoRow(Icons.wc, "Gender", gender),
                    const SizedBox(height: 5),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 5),
                    _buildInfoRow(Icons.email, "Email", email),
                    const SizedBox(height: 5),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 20),

                    // Add / Request button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canTap
                            ? () async {
                                await _sendFriendRequestFromChat();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canTap
                              ? const Color.fromRGBO(
                                  119, 136, 115, 1.0)
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(buttonText),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // View Details
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FriendProfileScreen(
                                name: name,
                                email: email,
                                avatarBase64: photoBase64,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color.fromRGBO(
                                119, 136, 115, 1.0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      message: _messageController.text.trim(),
    );
    _messageController.clear();
  }

  Widget _buildItemCard(Map<String, dynamic> data, bool isMe) {
    final cardData =
        data['cardData'] as Map<String, dynamic>? ?? {};
    final String title = cardData['title'] ?? 'Item';
    final String desc = cardData['description'] ?? '';
    final bool isFree = cardData['isFree'] ?? true;
    final double price = (cardData['price'] ?? 0).toDouble();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 250,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color.fromRGBO(119, 136, 115, 1.0),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.check_circle,
                  color: Color.fromRGBO(119, 136, 115, 1.0),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Item Claimed!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(119, 136, 115, 1.0),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (desc.isNotEmpty)
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isFree
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isFree
                    ? "FREE"
                    : "Price: RM ${price.toStringAsFixed(2)}",
                style: TextStyle(
                  color: isFree ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            GestureDetector(
              onTap: _showUserCard,
              child: CircleAvatar(
                radius: 18,
                backgroundColor:
                    const Color.fromRGBO(210, 220, 182, 1),
                backgroundImage: _profileImageProvider,
                child: _profileImageProvider == null
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0]
                                .toUpperCase()
                            : "?",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Pickup for: ${widget.itemName}",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data()
                        as Map<String, dynamic>;
                    final isMe =
                        data['senderId'] == widget.currentUserId;

                    if (data['type'] == 'item_claim') {
                      return _buildItemCard(data, isMe);
                    }

                    final Timestamp? timestamp =
                        data['timestamp'] as Timestamp?;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context)
                                  .size
                                  .width *
                              0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color.fromRGBO(
                                  119, 136, 115, 1.0)
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft:
                                const Radius.circular(12),
                            topRight:
                                const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey
                                  .withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            if (timestamp != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                        top: 4),
                                child: Text(
                                  DateFormat('h:mm a').format(
                                      timestamp.toDate()),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Coordinate pickup...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor:
                        const Color.fromRGBO(119, 136, 115, 1.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
