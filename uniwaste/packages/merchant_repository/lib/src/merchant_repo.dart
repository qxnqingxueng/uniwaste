import 'models/merchant.dart';

abstract class MerchantRepository {
  Stream<List<Merchant>> getMerchants();
  Future<void> createMerchant(Merchant merchant);
}
