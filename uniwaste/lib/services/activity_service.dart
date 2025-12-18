// lib/services/activity_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ActivityService {
  ActivityService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream activities for a single user
  Stream<QuerySnapshot> getUserActivities(String userId) {
    return _db
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> recordQrScan({
    required String userId,
    required String locationName,
    required int points,
  }) async {
    try {
      // 1. Create the history record
      await _addActivity(
        userId: userId,
        title: 'You scanned waste bin',
        description: 'Waste bin at $locationName',
        points: points,
        type: 'qr_scan',
      );

      // 2. Add points to user wallet
      await _addPointsToUser(userId, points);

      debugPrint("✅ QR Scan recorded for $userId at $locationName");
    } catch (e) {
      debugPrint("❌ Error recording QR scan: $e");
      rethrow;
    }
  }

  /// Generic single-activity writer used by ActivityShareHelper
  Future<String> addGenericActivity({
    required String userId,
    required String title,
    required String description,
    required int points,
    required String type,
    Map<String, dynamic>? extra,
  }) async {
    final docRef = _db.collection('activities').doc();

    await docRef.set({
      'userId': userId,
      'title': title,
      'description': description,
      'points': points,
      'type': type,
      'extra': extra ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });

    // also bump user points here
    await _addPointsToUser(userId, points); // 🔥 FIXED: use existing helper

    return docRef.id;
  }

  /// Internal helper: create ONE activity document for a user
  Future<void> _addActivity({
    required String userId,
    required String title,
    required String description,
    required int points,
    required String type, // e.g. 'p2p_donor', 'p2p_claimer'
    Map<String, dynamic>? extra, // optional extra metadata
  }) async {
    try {
      await _db.collection('activities').add({
        'userId': userId,
        'title': title,
        'description': description,
        'points': points,
        'type': type,
        'extra': extra ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error adding activity for $userId: $e');
    }
  }

  /// Internal helper: add (or create) points field on user document
  Future<void> _addPointsToUser(String userId, int deltaPoints) async {
    try {
      final userRef = _db.collection('users').doc(userId);

      await _db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final data = snap.data() ?? {};

        final oldPoints = (data['points'] ?? 0) as int;
        final newPoints = oldPoints + deltaPoints;

        tx.update(userRef, {'points': newPoints});

        // 🔥 Check if user crossed 3000-point threshold
        int oldMilestone = oldPoints ~/ 350;
        int newMilestone = newPoints ~/ 350;

        if (newMilestone > oldMilestone) {
          // User reached a new 3000 milestone → award voucher
          _grantVoucher(userId);
        }
      });
    } catch (e) {
      debugPrint('❌ Error updating points for $userId: $e');
    }
  }

  Future<void> _grantVoucher(String userId) async {
    final voucherRef =
        _db.collection('users').doc(userId).collection('vouchers').doc();

    await voucherRef.set({
      'title': "RM3 Discount Voucher",
      'brand': "UniWaste Rewards",
      'value': 3,
      'createdAt': FieldValue.serverTimestamp(),
      'expiry': DateTime.now().add(const Duration(days: 60)), // 2 months
      'isUsed': false,
    });

    debugPrint("🎉 Voucher granted to $userId");
  }

  /// Public: record a completed P2P transaction for BOTH users
  Future<void> recordP2PTransaction({
    required String listingId,
    required String itemName,
    required String donorId,
    required String claimerId,
    required String donorName,
    required String claimerName,
    required int donorPoints,
    required int claimerPoints,
  }) async {
    try {
      // donor activity
      await _addActivity(
        userId: donorId,
        title: 'You shared $itemName',
        description: 'Your food was claimed by $claimerName.',
        points: donorPoints,
        type: 'p2p_donor',
        extra: {
          'listingId': listingId,
          'itemName': itemName,
          'otherUserId': claimerId,
          'otherUserName': claimerName,
        },
      );

      // claimer activity
      await _addActivity(
        userId: claimerId,
        title: 'You claimed $itemName',
        description: 'You received food from $donorName.',
        points: claimerPoints,
        type: 'p2p_claimer',
        extra: {
          'listingId': listingId,
          'itemName': itemName,
          'otherUserId': donorId,
          'otherUserName': donorName,
        },
      );

      // update points
      await _addPointsToUser(donorId, donorPoints);
      await _addPointsToUser(claimerId, claimerPoints);

      debugPrint('✅ P2P transaction recorded for $donorId & $claimerId');
    } catch (e) {
      debugPrint('❌ recordP2PTransaction failed: $e');
    }
  }

  // OPTIONAL: simple test helper so we can test the screen easily
  Future<void> createTestActivity(String userId) async {
    await _addActivity(
      userId: userId,
      title: 'Test activity',
      description: 'If you see this, My Activity is working.',
      points: 1,
      type: 'test',
    );
  }
}
