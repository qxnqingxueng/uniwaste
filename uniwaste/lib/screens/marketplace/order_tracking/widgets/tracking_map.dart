import 'package:flutter/material.dart';

class TrackingMap extends StatelessWidget {
  const TrackingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // 1. Mock Map Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/Google_Maps_Logo_2020.svg/1024px-Google_Maps_Logo_2020.svg.png',
                fit: BoxFit.cover,
                errorBuilder:
                    (c, e, s) => const Center(
                      child: Icon(Icons.map, size: 50, color: Colors.grey),
                    ),
              ),
            ),
          ),

          // 2. Path Line
          Center(
            child: Container(
              height: 100,
              width: 2,
              color: Colors.green, // The route line
            ),
          ),

          // 3. Merchant Marker (Top)
          // REMOVED 'const' here
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.store, color: Colors.red, size: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: Colors.white,
                  child: const Text(
                    "Merchant",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 4. User Marker (Bottom)
          // REMOVED 'const' here
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: Colors.white,
                  child: const Text(
                    "You",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
