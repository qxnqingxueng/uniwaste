import 'package:equatable/equatable.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object> get props => [];
}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemModel> items;

  const CartLoaded({required this.items});

  double get totalAmount {
    if (items.isEmpty) return 0.0;
    return items.fold(
      0,
      (total, current) => total + (current.price * current.quantity),
    );
  }

  @override
  List<Object> get props => [items];
}

class CartError extends CartState {
  final String message;
  const CartError(this.message);

  @override
  List<Object> get props => [message];
}
