import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uniwaste/services/activity_service.dart';

class ActivityShareHelper {
  ActivityShareHelper._();

  static final ActivityService _activityService = ActivityService();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Helper to get user's display name from /users collection
  static Future<String?> _fetchUserName(String userId) async {
    try {
      final snap = await _db.collection('users').doc(userId).get();
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>;
      return (data['name'] ?? data['displayName'] ?? data['username']) as String?;
    } catch (_) {
      return null;
    }
  }

  /// Existing method (keeps the dialog logic for other parts of the app)
  static Future<void> recordAndMaybeShare({
    required BuildContext context,
    required String userId,
    required String title,
    required String description,
    required int points,
    required String type, // e.g. 'p2p_free', 'bin', 'merchant'
    Map<String, dynamic>? extra, // any extra info
    bool createActivity = true,
    String? userDisplayName,               // optional: you can still pass it
  }) async {
    String? activityId;

    if (createActivity) {
      activityId = await _activityService.addGenericActivity(
        userId: userId,
        title: title,
        description: description,
        points: points,
        type: type,
        extra: extra ?? {},
      );
    }

    final bool? shouldShare = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Share to Feed?'),
          content: const Text(
            'Do you want to share this activity so others can see your impact?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Share'),
            ),
          ],
        );
      },
    );

    if (shouldShare == true) {
      await shareToFeedDirectly(
        userId: userId,
        userDisplayName: userDisplayName,
        title: title,
        description: description,
        points: points,
        type: type,
        extra: extra,
        activityId: activityId,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shared to Feed ✅')),
        );
      }
    }
  }

  /// NEW METHOD: Posts directly to feed without asking
  static Future<void> shareToFeedDirectly({
    required String userId,
    required String? userDisplayName,
    required String title,
    required String description,
    required int points,
    required String type,
    Map<String, dynamic>? extra,
    String? activityId,
  }) async {
    final resolvedName = userDisplayName ?? await _fetchUserName(userId) ?? 'You';

    // Turn "You claimed a" -> "Jun claimed a"
    String toFeedText(String raw) {
      if (raw.startsWith('You ')) {
        return raw.replaceFirst('You ', '$resolvedName ');
      }
      if (raw.startsWith('you ')) {
        return raw.replaceFirst('you ', '$resolvedName ');
      }
      return raw;
    }

    final feedTitle = toFeedText(title);
    final feedDescription = toFeedText(description);

    await _db.collection('feed_posts').add({
      'userId': userId,
      'userName': resolvedName,
      'activityId': activityId,
      'title': feedTitle, // 👈 "Jun claimed a"
      'description': feedDescription, // 👈 "Jun received food from Daidi."
      'rawTitle': title,
      'rawDescription': description,
      'points': points,
      'type': type,
      'extra': extra ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'likedBy': <String>[],
    });
  }
}