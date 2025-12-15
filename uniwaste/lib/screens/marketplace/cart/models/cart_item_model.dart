import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final String id;
  final String name; // Primary name field
  final double price;
  final int quantity;
  final String notes;
  final String? merchantId;
  final String? merchantName; // Added to fix BottomSheet error
  final String? imagePath; // Added to fix BottomSheet error
  final bool isSelected;

  const CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes = '',
    this.merchantId,
    this.merchantName,
    this.imagePath,
    this.isSelected = true,
  });

  // ✅ 1. FIX CHECKOUT ERROR: Add a getter so .title works
  String get title => name;

  // ✅ 2. FIX ORDER_MODEL ERROR: Add toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'imagePath': imagePath,
      'isSelected': isSelected,
    };
  }

  // Helper to create from Map (useful later)
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'] ?? '',
      merchantId: map['merchantId'],
      merchantName: map['merchantName'],
      imagePath: map['imagePath'],
      isSelected: map['isSelected'] ?? true,
    );
  }

  // ✅ 3. FIX STATE UPDATES: CopyWith method
  CartItemModel copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? notes,
    String? merchantId,
    String? merchantName,
    String? imagePath,
    bool? isSelected,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      imagePath: imagePath ?? this.imagePath,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    quantity,
    notes,
    merchantId,
    merchantName,
    imagePath,
    isSelected,
  ];
}
