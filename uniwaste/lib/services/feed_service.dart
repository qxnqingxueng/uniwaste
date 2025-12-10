// lib/services/feed_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream all feed posts (latest first)
  Stream<QuerySnapshot> getFeedPosts() {
    return _db
        .collection('feed_posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Toggle like for a post
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final docRef = _db.collection('feed_posts').doc(postId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> likedBy = List.from(data['likedBy'] ?? []);
      int likesCount = (data['likesCount'] ?? likedBy.length) as int;

      if (likedBy.contains(userId)) {
        // unlike
        likedBy.remove(userId);
        likesCount = likesCount - 1;
      } else {
        // like
        likedBy.add(userId);
        likesCount = likesCount + 1;
      }

      transaction.update(docRef, {
        'likedBy': likedBy,
        'likesCount': likesCount,
      });
    });
  }

  /// Stream comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    return _db
        .collection('feed_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Add one comment
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    final commentsRef = _db
        .collection('feed_posts')
        .doc(postId)
        .collection('comments');

    await commentsRef.add({
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
