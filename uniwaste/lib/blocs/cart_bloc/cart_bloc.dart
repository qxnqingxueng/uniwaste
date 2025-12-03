import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

// EVENTS
abstract class CartEvent {}

class AddItem extends CartEvent {
  final CartItemModel item;
  AddItem(this.item);
}

class RemoveItem extends CartEvent {
  final String itemId;
  RemoveItem(this.itemId);
}

class ClearCart extends CartEvent {}

// STATES
class CartState {
  final List<CartItemModel> items;

  CartState({this.items = const []});

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

// BLOC LOGIC
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState()) {
    on<AddItem>((event, emit) {
      // Check if item already exists, update quantity if so
      final List<CartItemModel> updatedList = List.from(state.items);
      final index = updatedList.indexWhere((i) => i.id == event.item.id);

      if (index >= 0) {
        final existing = updatedList[index];
        updatedList[index] = CartItemModel(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + event.item.quantity, // Add counts
          notes: event.item.notes,
          image: existing.image,
        );
      } else {
        updatedList.add(event.item);
      }
      emit(CartState(items: updatedList));
    });

    on<ClearCart>((event, emit) => emit(CartState(items: [])));
  }
}
