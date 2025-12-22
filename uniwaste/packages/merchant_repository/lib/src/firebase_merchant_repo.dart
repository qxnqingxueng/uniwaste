import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'merchant_repo.dart';
import 'models/merchant.dart';

class FirebaseMerchantRepo implements MerchantRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference _merchantCollection;

  FirebaseMerchantRepo({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _merchantCollection = _firestore.collection('merchants');
  }

  @override
  Stream<List<Merchant>> getMerchants() {
    return _merchantCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // ✅ FIX 1: Pass data and ID directly to the model
        return Merchant.fromEntity(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  @override
  Future<void> createMerchant(Merchant merchant) async {
    try {
      await _merchantCollection
          .doc(merchant.id)
          // ✅ FIX 2: Use toDocument() directly
          .set(merchant.toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
