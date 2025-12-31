import 'package:equatable/equatable.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class LoadCart extends CartEvent {}

class AddItem extends CartEvent {
  final CartItemModel item;
  const AddItem(this.item);

  @override
  List<Object> get props => [item]; 
}

class RemoveItem extends CartEvent {
  final String itemId;
  const RemoveItem(this.itemId);

  @override
  List<Object> get props => [itemId];
}

class ClearCart extends CartEvent {}

// ✅ NEW: Event to toggle checkbox
class ToggleSelection extends CartEvent {
  final String itemId;
  const ToggleSelection(this.itemId);

  @override
  List<Object> get props => [itemId];
}

// ✅ NEW: Event to change quantity
class UpdateQuantity extends CartEvent {
  final String itemId;
  final int newQuantity;

  const UpdateQuantity(this.itemId, this.newQuantity);

  @override
  List<Object> get props => [itemId, newQuantity];
}
