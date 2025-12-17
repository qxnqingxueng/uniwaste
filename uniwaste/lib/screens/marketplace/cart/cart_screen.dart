import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_event.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_state.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';
import 'package:uniwaste/screens/marketplace/checkout/checkout_screen.dart';

// ✅ 1. IMPORT THE SHOP HOME SCREEN
import 'package:uniwaste/screens/marketplace/home/marketplace_home_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              context.read<CartBloc>().add(ClearCart());
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading)
            return const Center(child: CircularProgressIndicator());

          if (state is! CartLoaded || state.items.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder:
                      (context, index) =>
                          _buildCartItem(context, state.items[index]),
                ),
              ),
              _buildCheckoutBar(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            "Your cart is empty",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // ✅ 2. FIXED BUTTON NAVIGATION
          ElevatedButton(
            onPressed: () {
              // Navigate to the Shop Page instead of closing the app
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketplaceHomeScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            child: const Text(
              "Start Shopping",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemModel item) {
    return Row(
      children: [
        Checkbox(
          value: item.isSelected,
          activeColor: const Color(0xFF1B5E20),
          onChanged:
              (val) => context.read<CartBloc>().add(ToggleSelection(item.id)),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fastfood, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "RM ${item.price.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (item.quantity > 1) {
                  context.read<CartBloc>().add(
                    UpdateQuantity(item.id, item.quantity - 1),
                  );
                } else {
                  context.read<CartBloc>().add(RemoveItem(item.id));
                }
              },
            ),
            Text(
              "${item.quantity}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed:
                  () => context.read<CartBloc>().add(
                    UpdateQuantity(item.id, item.quantity + 1),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartLoaded state) {
    final selectedItems = state.items.where((i) => i.isSelected).toList();
    final total = selectedItems.fold(
      0.0,
      (sum, i) => sum + (i.price * i.quantity),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Total: RM ${total.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed:
                selectedItems.isEmpty
                    ? null
                    : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            child: Text(
              "Checkout (${selectedItems.length})",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
