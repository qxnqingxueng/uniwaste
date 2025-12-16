import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantEntity {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final bool isOpen;
  // ✅ 1. Add Categories
  final List<String> categories;

  const MerchantEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.isOpen,
    required this.categories,
  });

  // ✅ 2. Read from Firebase
  static MerchantEntity fromDocument(Map<String, dynamic> doc) {
    return MerchantEntity(
      id: doc['id'] as String? ?? '',
      name: doc['name'] as String? ?? '',
      description: doc['description'] as String? ?? '',
      imageUrl: doc['imageUrl'] as String? ?? '',
      rating: (doc['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: doc['isOpen'] as bool? ?? false,
      // Safely load list
      categories: List<String>.from(doc['categories'] ?? []),
    );
  }

  // ✅ 3. Save to Firebase
  Map<String, Object?> toDocument() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'isOpen': isOpen,
      'categories': categories,
    };
  }
}
