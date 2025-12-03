import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a chat room and sends the initial "Item Card" message
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
    // 1. Check for existing chat for this specific item
    final QuerySnapshot existingChats = await _db
        .collection('chats')
        .where('listingId', isEqualTo: listingId)
        .where('participants', arrayContains: claimerId)
        .limit(1)
        .get();

    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    // 2. Create new Chat Room
    final docRef = _db.collection('chats').doc();
    
    await docRef.set({
      'chatId': docRef.id,
      'listingId': listingId,
      'itemName': itemName,
      'participants': [donorId, claimerId],
      'participantNames': {
        donorId: donorName,
        claimerId: claimerName,
      },
      'lastMessage': 'Claimed: $itemName',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Send the "Item Card" as the first message
    await _db.collection('chats').doc(docRef.id).collection('messages').add({
      'senderId': claimerId, // The claimer "sends" this card
      'type': 'item_claim', // Special type for rendering the card
      'text': 'I have claimed this item!',
      'cardData': {
        'title': itemName,
        'description': itemDescription,
        'isFree': isFree,
        'price': price,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });

    return docRef.id;
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