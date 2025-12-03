import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uniwaste/services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserName;
  final String itemName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserName,
    required this.itemName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

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
            // Header
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color.fromRGBO(119, 136, 115, 1.0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Item Claimed!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(119, 136, 115, 1.0),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Item Info
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: const TextStyle(fontSize: 16)),
            Text("Pickup for: ${widget.itemName}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                    
                    // CHECK MESSAGE TYPE
                    if (data['type'] == 'item_claim') {
                      return _buildItemCard(data, isMe);
                    }

                    // Standard Text Message
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