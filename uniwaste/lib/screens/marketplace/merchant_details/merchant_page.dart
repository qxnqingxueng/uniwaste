import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ✅ IMPORTS FOR CART
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_event.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_state.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

// ✅ NAVIGATION IMPORTS
import 'package:uniwaste/screens/marketplace/cart/cart_screen.dart';
// ✅ IMPORT THE SOCIAL CHAT SCREEN
import 'package:uniwaste/screens/social/chat_detail_screen.dart';

class MerchantPage extends StatefulWidget {
  final String merchantId;
  final String merchantName;
  final String? imageUrl;

  const MerchantPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
    this.imageUrl,
  });

  @override
  State<MerchantPage> createState() => _MerchantPageState();
}

class _MerchantPageState extends State<MerchantPage> {
  bool _isChatLoading = false; // To show spinner on Chat button

  // ✅ LOGIC: Add Item to Global Cart (Bloc)
  void _addToCart(String itemId, String name, double price, String? imagePath) {
    final cartItem = CartItemModel(
      id: itemId,
      name: name,
      price: price,
      quantity: 1,
      imagePath: imagePath,
      merchantId: widget.merchantId,
      merchantName: widget.merchantName,
      isSelected: true,
    );

    context.read<CartBloc>().add(AddItem(cartItem));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added $name to cart"),
        duration: const Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green[700],
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  // ✅ NEW LOGIC: Find or Create Chat, then Navigate
  Future<void> _handleMerchantChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login to chat")));
      return;
    }

    setState(() => _isChatLoading = true);

    try {
      final chatsRef = FirebaseFirestore.instance.collection('chats');

      // 1. Check if chat exists (query by participants)
      // Note: Firestore array-contains only handles one value efficiently.
      // We query for current user, then filter manually for merchant.
      final querySnapshot =
          await chatsRef.where('participants', arrayContains: user.uid).get();

      String? existingChatId;

      for (var doc in querySnapshot.docs) {
        final List participants = doc['participants'];
        if (participants.contains(widget.merchantId)) {
          existingChatId = doc.id;
          break;
        }
      }

      String chatIdToUse = existingChatId ?? '';

      // 2. If no chat exists, create one
      if (existingChatId == null) {
        final newChatDoc = await chatsRef.add({
          'participants': [user.uid, widget.merchantId],
          'participantNames': {
            user.uid: user.displayName ?? 'Student',
            widget.merchantId: widget.merchantName,
          },
          'lastMessage': 'Chat started',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        chatIdToUse = newChatDoc.id;
      }

      if (!mounted) return;

      // 3. Navigate to existing Social Module Chat Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChatDetailScreen(
                chatId: chatIdToUse,
                currentUserId: user.uid,
                otherUserId: widget.merchantId,
                otherUserName: widget.merchantName,
                itemName: "General Inquiry", // Default context
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening chat: $e")));
    } finally {
      if (mounted) setState(() => _isChatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.merchantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Error: Invalid Merchant ID")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.orange,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.merchantName,
                    style: const TextStyle(
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                    ),
                  ),
                  background:
                      widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? _buildSafeImage(widget.imageUrl!)
                          : Container(
                            color: Colors.orange[300],
                            child: const Icon(
                              Icons.store,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Info & Chat Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Surplus Food Menu",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Save food, save money!",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // ✅ UPDATED CHAT BUTTON
                      OutlinedButton.icon(
                        onPressed: _isChatLoading ? null : _handleMerchantChat,
                        icon:
                            _isChatLoading
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 18,
                                ),
                        label: const Text("Chat"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[200]!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Food List
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('merchants')
                        .doc(widget.merchantId)
                        .collection('items')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );

                  final items = snapshot.data!.docs;
                  if (items.isEmpty)
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("No items available today."),
                        ),
                      ),
                    );

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final data = items[index].data() as Map<String, dynamic>;
                      final itemId = items[index].id;
                      final qty = data['quantity'] ?? 0;
                      if (qty <= 0) return const SizedBox.shrink();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: SizedBox(
                            width: 70,
                            height: 70,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildSafeImage(data['imagePath']),
                            ),
                          ),
                          title: Text(
                            data['name'] ?? 'Food',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "RM ${(data['price'] ?? 0).toStringAsFixed(2)}",
                              ),
                              Text(
                                "$qty left",
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: InkWell(
                            onTap:
                                () => _addToCart(
                                  itemId,
                                  data['name'],
                                  (data['price'] ?? 0).toDouble(),
                                  data['imagePath'],
                                ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "ADD",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: items.length),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // STICKY CART BAR
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              int totalCount = 0;
              double totalPrice = 0.0;
              if (state is CartLoaded) {
                totalCount = state.items.fold(
                  0,
                  (sum, item) => sum + item.quantity,
                );
                totalPrice = state.items.fold(
                  0,
                  (sum, item) => sum + (item.price * item.quantity),
                );
              }
              if (totalCount == 0) return const SizedBox.shrink();

              return Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$totalCount items",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "RM ${totalPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Text(
                              "View Cart",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSafeImage(String? data) {
    if (data == null || data.isEmpty)
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.fastfood, color: Colors.grey),
      );
    try {
      if (data.startsWith('http'))
        return Image.network(
          data,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.error),
        );
      return Image.memory(
        base64Decode(data),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.error),
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image),
      );
    }
  }
}
