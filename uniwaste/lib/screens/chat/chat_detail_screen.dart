import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uniwaste/services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId; // ADDED
  final String otherUserName;
  final String itemName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId, // ADDED
    required this.otherUserName,
    required this.itemName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  Uint8List? _otherUserImageBytes;
  Map<String, dynamic>? _otherUserData;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserProfile();
  }

  // --- Fetch Other User Data ---
  Future<void> _fetchOtherUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (doc.exists) {
        setState(() {
          _otherUserData = doc.data();
          if (_otherUserData != null &&
              _otherUserData!['photoBase64'] != null &&
              _otherUserData!['photoBase64'].isNotEmpty) {
            _otherUserImageBytes = base64Decode(_otherUserData!['photoBase64']);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  // --- Show User Profile Dialog ---
  void _showUserCard() {
    showDialog(
      context: context,
      builder: (context) {
        // Defaults if data is missing
        final String name = _otherUserData?['name'] ?? widget.otherUserName;
        final String gender = _otherUserData?['gender'] ?? 'Not Specified';
        // Assume ranking is stored or default to 'Member'
        final String ranking = _otherUserData?['ranking'] ?? 'LV1 Eco-Warrior'; 

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Picture
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color.fromRGBO(119, 136, 115, 1.0), width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _otherUserImageBytes != null
                        ? MemoryImage(_otherUserImageBytes!)
                        : null,
                    child: _otherUserImageBytes == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(fontSize: 40, color: Colors.grey),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name
                Text(
                  name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Leadership Ranking Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                // Details Row
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.wc, "Gender", gender),
                const SizedBox(height: 10),
                // You can add more fields here if available
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Close"),
                  ),
                )
              ],
            ),
          ),
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
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        )
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

  // --- Helper to Build the Item Card Bubble ---
  Widget _buildItemCard(Map<String, dynamic> data, bool isMe) {
    final cardData = data['cardData'] as Map<String, dynamic>? ?? {};
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
          border: Border.all(color: const Color.fromRGBO(119, 136, 115, 1.0), width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color.fromRGBO(119, 136, 115, 1.0)),
                const SizedBox(width: 8),
                const Expanded(
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (desc.isNotEmpty)
              Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isFree ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isFree ? "FREE" : "Price: RM ${price.toStringAsFixed(2)}",
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            // --- CLICKABLE PROFILE PICTURE ---
            GestureDetector(
              onTap: _showUserCard,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color.fromRGBO(210, 220, 182, 1),
                backgroundImage: _otherUserImageBytes != null
                    ? MemoryImage(_otherUserImageBytes!)
                    : null,
                child: _otherUserImageBytes == null
                    ? Text(
                        widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : "?",
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            
            // --- NAME & ITEM INFO ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Pickup for: ${widget.itemName}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.normal),
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.currentUserId;

                    if (data['type'] == 'item_claim') {
                      return _buildItemCard(data, isMe);
                    }

                    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? const Color.fromRGBO(119, 136, 115, 1.0) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                          ),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                            if (timestamp != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('h:mm a').format(timestamp.toDate()),
                                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
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
          // Input Area
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
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