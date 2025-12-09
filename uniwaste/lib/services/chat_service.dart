import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
        await chatRef.update({
          'participantNames': participantNames,
        });
      }
    }

    return chatId;
  }

  /// Creates (or reuses) a friend chat between donor & claimer
  /// and sends the initial "Item Card" message inside that chat.
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
    // 🔸 Use the SAME chatId rule as friend chats
    final String chatId = _buildFriendChatId(donorId, claimerId);
    final chatRef = _db.collection('chats').doc(chatId);
    final chatSnap = await chatRef.get();

    final participants = [donorId, claimerId]..sort();
    final Map<String, String> participantNames = {
      donorId: donorName,
      claimerId: claimerName,
    };

    if (!chatSnap.exists) {
      // First time these two users interact → create the chat doc
      await chatRef.set({
        'chatId': chatId,
        'participants': participants,
        'participantNames': participantNames,
        'itemName': itemName,                     // last claimed item
        'type': 'friend',                         // SAME type as friend chat
        'lastMessage': 'Claimed: $itemName',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Chat already exists → just update metadata
      await chatRef.update({
        'participantNames': participantNames,
        'itemName': itemName,
        'lastMessage': 'Claimed: $itemName',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    // 3. Send the "Item Card" as a message inside this chat
    await chatRef.collection('messages').add({
      'senderId': claimerId,           // The claimer "sends" this card
      'type': 'item_claim',            // Special type for rendering the card
      'text': 'I have claimed this item!',
      'listingId': listingId,          // optional reference
      'cardData': {
        'title': itemName,
        'description': itemDescription,
        'isFree': isFree,
        'price': price,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });

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

    await _db.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
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