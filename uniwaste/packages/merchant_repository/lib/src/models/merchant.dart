import '../entities/merchant_entity.dart';

class Merchant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final bool isOpen;
  // ✅ 1. Add categories field
  final List<String> categories;

  const Merchant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.isOpen,
    this.categories = const [], // ✅ Default to empty
  });

  // ✅ 2. Update Empty Constructor
  static const empty = Merchant(
    id: '',
    name: '',
    description: '',
    imageUrl: '',
    rating: 0,
    isOpen: false,
    categories: [],
  );

  // ✅ 3. Update fromEntity
  static Merchant fromEntity(MerchantEntity entity) {
    return Merchant(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      imageUrl: entity.imageUrl,
      rating: entity.rating,
      isOpen: entity.isOpen,
      categories: entity.categories, // Map logic
    );
  }

  // ✅ 4. Update toEntity
  MerchantEntity toEntity() {
    return MerchantEntity(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      rating: rating,
      isOpen: isOpen,
      categories: categories,
    );
  }
}
