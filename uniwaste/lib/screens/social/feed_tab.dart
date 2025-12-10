// lib/screens/social/feed_tab.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/services/feed_service.dart';

class FeedTab extends StatelessWidget {
  FeedTab({super.key});

  final FeedService _feedService = FeedService();

  @override
  Widget build(BuildContext context) {
    final currentUser =
        context.select((AuthenticationBloc bloc) => bloc.state.user);
    final String currentUserId = currentUser?.userId ?? '';
    final String currentUserName = currentUser?.name ?? 'Someone';

    return StreamBuilder<QuerySnapshot>(
      stream: _feedService.getFeedPosts(),
      builder: (context, snapshot) {
        // ⏳ Loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ❌ Error state
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading feed: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No posts yet. Share an activity to get started!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final postId = doc.id;
            final String userId = (data['userId'] ?? '') as String;
            final String userName =
                (data['userName'] ?? 'UniWaste User') as String;
            final String title = (data['title'] ?? '') as String;
            final String description =
                (data['description'] ?? '') as String;

            final Timestamp? ts = data['createdAt'] as Timestamp?;
            final DateTime? time = ts?.toDate();
            final String timeAgo = time == null
                ? ''
                : DateFormat('dd MMM • HH:mm').format(time);

            final List<dynamic> likedBy = data['likedBy'] ?? [];
            final bool isLiked = likedBy.contains(currentUserId);
            final int likesCount =
                (data['likesCount'] ?? likedBy.length) as int;

            return _buildFeedPost(
              context: context,
              postId: postId,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
              userId: userId,
              userName: userName,
              timeAgo: timeAgo,
              title: title,
              content: description,
              likes: likesCount,
              isLiked: isLiked,
            );
          },
        );
      },
    );
  }

  Widget _buildFeedPost({
    required BuildContext context,
    required String postId,
    required String currentUserId,
    required String currentUserName,
    required String userId,
    required String userName,
    required String timeAgo,
    required String title,
    required String content,
    required int likes,
    required bool isLiked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Row(
            children: [
              FeedUserAvatar(
                userId: userId,
                userName: userName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // ⬇️ triple-dot removed
              // Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),

          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Post content
          Text(
            content,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              // ❤️ like
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                iconColor: isLiked ? Colors.red : Colors.grey[600],
                label: '$likes',
                onTap: currentUserId.isEmpty
                    ? null
                    : () async {
                        await _feedService.toggleLike(
                          postId: postId,
                          userId: currentUserId,
                        );
                      },
              ),
              const SizedBox(width: 16),

              // 💬 comments (message)
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: 'Comments',
                onTap: () {
                  _openCommentsBottomSheet(
                    context: context,
                    postId: postId,
                    currentUserId: currentUserId,
                    currentUserName: currentUserName,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color? iconColor,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Bottom sheet for comments/messages per post
  void _openCommentsBottomSheet({
    required BuildContext context,
    required String postId,
    required String currentUserId,
    required String currentUserName,
  }) {
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 12,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _feedService.getComments(postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading comments: ${snapshot.error}',
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('No comments yet. Be the first!'),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final userName =
                              (data['userName'] ?? 'User') as String;
                          final text =
                              (data['text'] ?? '') as String;
                          final ts =
                              data['timestamp'] as Timestamp?;
                          final time = ts?.toDate();
                          final timeText = time == null
                              ? ''
                              : DateFormat('dd MMM • HH:mm').format(time);

                          return ListTile(
                            dense: true,
                            title: Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(text),
                            trailing: Text(
                              timeText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final text = controller.text.trim();
                          if (text.isEmpty || currentUserId.isEmpty) return;

                          await _feedService.addComment(
                            postId: postId,
                            userId: currentUserId,
                            userName: currentUserName,
                            text: text,
                          );
                          controller.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Avatar that loads from /users/{userId}.photoBase64 / photoUrl
/// Fallback: coloured circle with the user's initial.
class FeedUserAvatar extends StatelessWidget {
  final String userId;
  final String userName;

  const FeedUserAvatar({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // If no userId, just show initial
    if (userId.isEmpty) {
      return _buildInitialAvatar(userName);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildInitialAvatar(userName);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // 👇 your actual fields
        final String? base64Image = data['photoBase64'] as String?;
        final String? photoUrl = data['photoUrl'] as String?;

        // 1) Try base64 image
        if (base64Image != null && base64Image.isNotEmpty) {
          try {
            Uint8List bytes = base64Decode(base64Image);
            return CircleAvatar(
              radius: 20,
              backgroundImage: MemoryImage(bytes),
            );
          } catch (_) {
            // if decode fails, fall through to URL / initial
          }
        }

        // 2) Try URL image (if you ever use photoUrl later)
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(photoUrl),
          );
        }

        // 3) Fallback to initial avatar
        return _buildInitialAvatar(userName);
      },
    );
  }

  Widget _buildInitialAvatar(String name) {
    final String initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFA1BC98),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
