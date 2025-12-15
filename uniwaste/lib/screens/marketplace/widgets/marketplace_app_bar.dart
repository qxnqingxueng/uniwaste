import 'package:flutter/material.dart';

class MarketplaceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showCart;

  const MarketplaceAppBar({
    super.key,
    required this.title,
    this.showCart = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      // 1. REUSABLE BACK LOGIC
      // Automatically shows the Back Arrow if we can go back
      leading:
          Navigator.canPop(context)
              ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed:
                    () => Navigator.pop(context), // Shared Navigation Function
              )
              : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (showCart)
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {
              // Standard route to cart from anywhere
              // Navigator.pushNamed(context, '/cart');
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
