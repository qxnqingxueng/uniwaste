import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // for BuildContext
import 'package:uniwaste/services/activity_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();

  /// Build a deterministic chatId for a pair of users
  String _buildFriendChatId(String userAId, String userBId) {
    final ids = [userAId, userBId]..sort();
    return 'friend_${ids[0]}_${ids[1]}';
  }

  // 🔹 Get or create a single friend chat between two users
  Future<String> getOrCreateChat({
    required String userAId,
    required String userBId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    final chatId = _buildFriendChatId(userAId, userBId);
    final chatRef = _db.collection('chats').doc(chatId);
    final snap = await chatRef.get();

    final participants = [userAId, userBId]..sort();
    final Map<String, String> participantNames = {
      userAId: currentUserName,
      userBId: otherUserName,
    };

    if (!snap.exists) {
      // First time this pair ever chats
      await chatRef.set({
        'chatId': chatId,
        'participants': participants,
        'participantNames': participantNames,
        'itemName': 'Friend chat', // header default
        'type': 'friend',
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Ensure participantNames exists and is up to date
      final data = snap.data() as Map<String, dynamic>;
      if (data['participantNames'] == null) {
        await chatRef.update({'participantNames': participantNames});
      }
    }

    return chatId;
  }

  /// Creates (or reuses) a friend chat between donor & claimer
  /// and sends an "Item Card" message inside that chat.
  Future<String> createChatAndSendCard({
    required String listingId,
    required String donorId,
    required String claimerId,
    required String donorName,
    required String claimerName,
    required String itemName,
    required String itemDescription,
    required bool isFree,
    required double price,
  }) async {
    final String chatId = _buildFriendChatId(donorId, claimerId);
    final chatRef = _db.collection('chats').doc(chatId);
    final chatSnap = await chatRef.get();

    final participants = [donorId, claimerId]..sort();
    final Map<String, String> participantNames = {
      donorId: donorName,
      claimerId: claimerName,
    };

    // ✅ MODIFIED: Added 'lastSenderId' to set and update
    if (!chatSnap.exists) {
      await chatRef.set({
        'chatId': chatId,
        'participants': participants,
        'participantNames': participantNames,
        'itemName': itemName,
        'type': 'friend',
        'lastMessage': 'Claimed: $itemName',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': claimerId, // <--- Track who sent this
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await chatRef.update({
        'participantNames': participantNames,
        'itemName': itemName,
        'lastMessage': 'Claimed: $itemName',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': claimerId, // <--- Track who sent this
      });
    }

    // Item card message
    await chatRef.collection('messages').add({
      'senderId': claimerId,
      'type': 'item_claim',
      'text': 'I have claimed this item!',
      'cardData': {
        'title': itemName,
        'description': itemDescription,
        'isFree': isFree,
        'price': price,
        'listingId': listingId,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Record donor + claimer activities + points
    await _activityService.recordP2PTransaction(
      listingId: listingId,
      itemName: itemName,
      donorId: donorId,
      claimerId: claimerId,
      donorName: donorName,
      claimerName: claimerName,
      donorPoints: isFree ? 100 : 50,
      claimerPoints: isFree ? 50 : 50,
    );

    return chatId;
  }

  /// Sends a standard text message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'type': 'text',
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ✅ MODIFIED: Added 'lastSenderId'
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId, // <--- Track who sent this
    });
  }

  /// Delete a whole chat (all messages + chat doc).
  Future<void> deleteChat(String chatId) async {
    try {
      final chatRef = _db.collection('chats').doc(chatId);

      // 1. Delete all messages in subcollection
      final messagesSnap = await chatRef.collection('messages').get();

      final batch = _db.batch();
      for (final doc in messagesSnap.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete chat document itself
      batch.delete(chatRef);

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting chat $chatId: $e');
      rethrow; // let UI handle error if needed
    }
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}