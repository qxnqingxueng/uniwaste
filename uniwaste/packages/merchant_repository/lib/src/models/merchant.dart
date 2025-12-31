class Merchant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final List<String> categories;
  final double deliveryFee;
  final String deliveryTime;

  const Merchant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.categories,
    required this.deliveryFee,
    required this.deliveryTime,
  });

  /// 1. READ: Create Merchant from Firestore Data
  static Merchant fromEntity(Map<String, dynamic> data, String id) {
    return Merchant(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      categories: List<String>.from(data['categories'] ?? []),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      deliveryTime: data['deliveryTime'] ?? '',
    );
  }

  /// 2. WRITE: Convert Merchant to Firestore Data
  Map<String, dynamic> toDocument() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'categories': categories,
      'deliveryFee': deliveryFee,
    };
  }

  /// Optional: Helper for empty state
  static const empty = Merchant(
    id: '',
    name: '',
    description: '',
    imageUrl: '',
    rating: 0,
    categories: [],
    deliveryFee: 0,
    deliveryTime: '',
  );
}
