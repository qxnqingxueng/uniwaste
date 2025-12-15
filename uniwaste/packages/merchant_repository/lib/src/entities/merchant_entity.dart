import 'package:equatable/equatable.dart';

class MerchantEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final bool isOpen;
  final String location;

  const MerchantEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.isOpen,
    required this.location,
  });

  // Convert to Map for Firestore
  Map<String, Object?> toDocument() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'isOpen': isOpen,
      'location': location,
    };
  }

  // Create from Map (Firestore)
  static MerchantEntity fromDocument(Map<String, dynamic> doc) {
    return MerchantEntity(
      id: doc['id'] as String? ?? '',
      name: doc['name'] as String? ?? 'Unknown',
      description: doc['description'] as String? ?? '',
      imageUrl: doc['imageUrl'] as String? ?? '',
      rating: (doc['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: doc['isOpen'] as bool? ?? false,
      location: doc['location'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, imageUrl, rating, isOpen, location];
}
