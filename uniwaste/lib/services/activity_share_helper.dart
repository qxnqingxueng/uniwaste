// lib/services/activity_share_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uniwaste/services/activity_service.dart';

class ActivityShareHelper {
  ActivityShareHelper._();

  static final ActivityService _activityService = ActivityService();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generic helper:
  /// 1. (Optionally) record an activity
  /// 2. Ask user if they want to share it to Feed
  /// 3. If yes → create a feed post
  static Future<void> recordAndMaybeShare({
    required BuildContext context,
    required String userId,
    required String title,
    required String description,
    required int points,
    required String type,                  // e.g. 'p2p_free', 'bin', 'merchant'
    Map<String, dynamic>? extra,           // any extra info
    bool createActivity = true,            // <-- NEW: default true
  }) async {
    String? activityId;

    // 1. Create activity only if requested
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

    // 2. Ask if user wants to share as a post
    final bool? shouldShare = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

    if (shouldShare != true) return;

    // 3. Create a simple feed post
    await _db.collection('feed_posts').add({
      'userId': userId,
      'activityId': activityId,        // may be null if createActivity == false
      'title': title,
      'description': description,
      'points': points,
      'type': type,
      'extra': extra ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared to Feed ✅')),
      );
    }
  }
}
