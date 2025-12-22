import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

// ✅ IMPORT the separate Event and State files
import 'cart_event.dart';
import 'cart_state.dart';

// ✅ EXPORT them so checkout_screen.dart can see them too!
export 'cart_event.dart';
export 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  // Internal list to hold items
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

  // Toggle Selection
  void _onToggleSelection(ToggleSelection event, Emitter<CartState> emit) {
    final index = _items.indexWhere((item) => item.id == event.itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isSelected: !_items[index].isSelected,
      );
      emit(CartLoaded(items: List.from(_items)));
    }
  }

  // Update Quantity
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
