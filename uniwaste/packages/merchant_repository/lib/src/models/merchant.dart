import 'package:equatable/equatable.dart';
import '../entities/merchant_entity.dart';

class Merchant extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final bool isOpen;
  final String location;

  const Merchant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.isOpen,
    required this.location,
  });

  // Convert from Entity (Database) to Model (App)
  static Merchant fromEntity(MerchantEntity entity) {
    return Merchant(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      imageUrl: entity.imageUrl,
      rating: entity.rating,
      isOpen: entity.isOpen,
      location: entity.location,
    );
  }

  // Convert from Model to Entity
  MerchantEntity toEntity() {
    return MerchantEntity(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      rating: rating,
      isOpen: isOpen,
      location: location,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, imageUrl, rating, isOpen, location];
}
