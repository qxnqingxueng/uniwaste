class CartItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String notes;
  final String image;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes = '',
    required this.image,
  });

  double get total => price * quantity;
}
