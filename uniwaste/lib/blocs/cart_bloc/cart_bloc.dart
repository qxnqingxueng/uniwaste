import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

// EVENTS
abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddItem extends CartEvent {
  final CartItemModel item;
  AddItem(this.item);
  @override
  List<Object?> get props => [item];
}

class RemoveItem extends CartEvent {
  final String itemId;
  RemoveItem(this.itemId);
}

class ClearCart extends CartEvent {}

// STATES
class CartState extends Equatable {
  final List<CartItemModel> items;
  // This 'version' integer effectively forces a rebuild on every change
  final int version;

  const CartState({this.items = const [], this.version = 0});

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [items, version]; // Watching 'version' ensures updates are caught
}

// BLOC LOGIC
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddItem>((event, emit) {
      print("🛒 BLOC: AddItem Triggered -> ${event.item.name}");

      // Create a NEW list instance (Critical for Bloc to detect change)
      final List<CartItemModel> updatedList = List.from(state.items);

      final index = updatedList.indexWhere((i) => i.id == event.item.id);

      if (index >= 0) {
        print("🛒 BLOC: Updating existing item quantity");
        final existing = updatedList[index];
        // Replace the item with a new copy with updated quantity
        updatedList[index] = CartItemModel(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + event.item.quantity,
          notes: event.item.notes,
          image: existing.image,
        );
      } else {
        print("🛒 BLOC: Adding new item to list");
        updatedList.add(event.item);
      }

      // Emit new state with incremented version number
      emit(CartState(items: updatedList, version: state.version + 1));

      print(
        "🛒 BLOC: New State Emitted. Count: ${updatedList.length}, Version: ${state.version + 1}",
      );
    });

    on<ClearCart>((event, emit) => emit(const CartState(items: [])));
  }
}
