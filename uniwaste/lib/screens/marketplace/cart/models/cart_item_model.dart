class CartItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String notes;
  final String image;

  // NEW: Store merchant info so we can group them later
  final String merchantName;
  final String merchantLocation;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes = '',
    required this.image,
    required this.merchantName, // Required
    this.merchantLocation = "UM Campus", // Default
  });

  double get total => price * quantity;
}
