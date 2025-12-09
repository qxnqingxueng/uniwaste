import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

// --- EVENTS ---
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

class ClearCart extends CartEvent {}

// --- STATE ---
class CartState extends Equatable {
  final List<CartItemModel> items;
  final int version; // Forces UI rebuild

  const CartState({this.items = const [], this.version = 0});

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [items, version];
}

// --- BLOC ---
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddItem>((event, emit) {
      final List<CartItemModel> updatedList = List.from(state.items);

      // Check if item already exists
      final index = updatedList.indexWhere((i) => i.id == event.item.id);

      if (index >= 0) {
        // Update quantity if exists
        final existing = updatedList[index];
        updatedList[index] = CartItemModel(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + event.item.quantity,
          notes: event.item.notes,
          image: existing.image,
          merchantName: existing.merchantName,
        );
      } else {
        // Add new if not
        updatedList.add(event.item);
      }

      // Emit new state with updated Version number
      emit(CartState(items: updatedList, version: state.version + 1));
    });

    on<ClearCart>((event, emit) => emit(const CartState(items: [])));
  }
}
