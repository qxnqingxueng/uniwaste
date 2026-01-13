import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';
import 'cart_event.dart';
import 'cart_state.dart';
export 'cart_event.dart';
export 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final List<CartItemModel> _items = [];

  CartBloc() : super(CartLoading()) {
    on<LoadCart>(_onLoadCart);
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<ClearCart>(_onClearCart);
    on<ToggleSelection>(_onToggleSelection);
    on<UpdateQuantity>(_onUpdateQuantity);
  }

  void _onLoadCart(LoadCart event, Emitter<CartState> emit) {
    emit(CartLoaded(items: List.from(_items)));
  }

  void _onAddItem(AddItem event, Emitter<CartState> emit) {
    // Check if item exists to increment quantity
    final index = _items.indexWhere((i) => i.id == event.item.id);
    if (index >= 0) {
      // If yes, update quantity instead of adding a duplicate row
      _items[index] = _items[index].copyWith(
        // Use copyWith to create a new instance with updated quantity
        quantity: _items[index].quantity + event.item.quantity,
      );
    } else {
      // If no, add it as a new item
      _items.add(event.item);
    }
    //Send the new list to UI
    emit(CartLoaded(items: List.from(_items)));
  }

  void _onRemoveItem(RemoveItem event, Emitter<CartState> emit) {
    _items.removeWhere((item) => item.id == event.itemId); // Remove item by ID
    emit(CartLoaded(items: List.from(_items)));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    _items.clear(); // Clear all items
    emit(const CartLoaded(items: []));
  }

  void _onToggleSelection(ToggleSelection event, Emitter<CartState> emit) {
    // Toggle selection
    final index = _items.indexWhere(
      (item) => item.id == event.itemId,
    ); // Find the item
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        // Toggle isSelected
        isSelected: !_items[index].isSelected,
      );
      emit(CartLoaded(items: List.from(_items)));
    }
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    // Update quantity
    // Find the item
    final index = _items.indexWhere((item) => item.id == event.itemId);
    if (index != -1) {
      if (event.newQuantity > 0) {
        // Update the count
        _items[index] = _items[index].copyWith(quantity: event.newQuantity);
      } else {
        // Remove the item if quantity is zero
        _items.removeAt(index);
      }
      emit(CartLoaded(items: List.from(_items)));
    }
  }
}
