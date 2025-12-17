import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_event.dart';
import 'package:uniwaste/screens/marketplace/cart/models/cart_item_model.dart';

class ItemDetailsBottomSheet extends StatefulWidget {
  final String itemId;
  final String itemName;
  final double price;
  final String merchantName;
  final String itemImage;

  const ItemDetailsBottomSheet({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.merchantName,
    required this.itemImage,
  });

  @override
  State<ItemDetailsBottomSheet> createState() => _ItemDetailsBottomSheetState();
}

class _ItemDetailsBottomSheetState extends State<ItemDetailsBottomSheet> {
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  // Helper to build image safely (Base64 vs Network vs Asset)
  Widget _buildSafeImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
      );
    } else if (path.length > 200) {
      // Base64 check
      try {
        return Image.memory(base64Decode(path), fit: BoxFit.cover);
      } catch (e) {
        return Container(color: Colors.grey[200]);
      }
    } else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalPrice = widget.price * _quantity;

    return Container(
      padding: const EdgeInsets.all(20),
      height:
          MediaQuery.of(context).size.height * 0.85, // Takes up 85% of screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // 2. Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: _buildSafeImage(widget.itemImage),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Title & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.itemName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "RM ${widget.price.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Sold by ${widget.merchantName}",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const Divider(height: 30),

          // 4. Quantity Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quantity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 18),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        "$_quantity",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _quantity++);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Notes
          const Text(
            "Special Instructions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: "E.g. No spicy, less sauce...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const Spacer(),

          // 6. Add to Cart Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Create Item Model
                final newItem = CartItemModel(
                  id: widget.itemId,
                  name: widget.itemName, // Matches model property
                  price: widget.price,
                  quantity: _quantity,
                  merchantName: widget.merchantName,
                  imagePath: widget.itemImage,
                  notes: _notesController.text.trim(),
                  isSelected: true,
                );

                // Add to Bloc
                context.read<CartBloc>().add(AddItem(newItem));

                // Close Sheet
                Navigator.pop(context);

                // Show tiny feedback snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${widget.itemName} added to cart!"),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                "Add to Cart - RM ${totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
