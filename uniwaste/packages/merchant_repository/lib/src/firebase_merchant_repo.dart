import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'entities/merchant_entity.dart';
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
        return Merchant.fromEntity(
          MerchantEntity.fromDocument(doc.data() as Map<String, dynamic>),
        );
      }).toList();
    });
  }

  @override
  Future<void> createMerchant(Merchant merchant) async {
    try {
      await _merchantCollection
          .doc(merchant.id)
          .set(merchant.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
