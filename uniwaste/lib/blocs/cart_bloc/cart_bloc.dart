import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_event.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_state.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  // Internal list to hold items
  List<CartItemModel> _items = [];

  CartBloc() : super(CartLoading()) {
    on<LoadCart>(_onLoadCart);
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<ClearCart>(_onClearCart);
    on<ToggleSelection>(_onToggleSelection); // ✅ Handle Toggle
    on<UpdateQuantity>(_onUpdateQuantity); // ✅ Handle Quantity
  }

  void _onLoadCart(LoadCart event, Emitter<CartState> emit) {
    emit(CartLoaded(items: List.from(_items)));
  }

  void _onAddItem(AddItem event, Emitter<CartState> emit) {
    // Check if item exists to increment quantity instead of duplicate
    final index = _items.indexWhere((i) => i.id == event.item.id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + event.item.quantity,
      );
    } else {
      _items.add(event.item);
    }
    emit(CartLoaded(items: List.from(_items)));
  }

  void _onRemoveItem(RemoveItem event, Emitter<CartState> emit) {
    _items.removeWhere((item) => item.id == event.itemId);
    emit(CartLoaded(items: List.from(_items)));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    _items.clear();
    emit(const CartLoaded(items: []));
  }

  // ✅ LOGIC: Toggle Selection
  void _onToggleSelection(ToggleSelection event, Emitter<CartState> emit) {
    final index = _items.indexWhere((item) => item.id == event.itemId);
    if (index != -1) {
      // Toggle the boolean
      _items[index] = _items[index].copyWith(
        isSelected: !_items[index].isSelected,
      );
      emit(CartLoaded(items: List.from(_items)));
    }
  }

  // ✅ LOGIC: Update Quantity
  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    final index = _items.indexWhere((item) => item.id == event.itemId);
    if (index != -1) {
      if (event.newQuantity > 0) {
        _items[index] = _items[index].copyWith(quantity: event.newQuantity);
      } else {
        // Optional: Remove item if quantity goes to 0
        _items.removeAt(index);
      }
      emit(CartLoaded(items: List.from(_items)));
    }
  }
}
