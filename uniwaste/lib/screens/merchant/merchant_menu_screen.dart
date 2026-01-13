import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MerchantMenuScreen extends StatelessWidget {
  const MerchantMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final merchantId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Menu")),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Food", style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddEditDialog(context, merchantId: merchantId),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('merchants')
                .doc(merchantId)
                .collection('items')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Menu is empty.\nAdd items to start selling!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index].data() as Map<String, dynamic>;
              final itemId = items[index].id;

              // Safe Image Decoding
              Widget imageWidget;
              try {
                if (data['imagePath'] != null &&
                    data['imagePath'].toString().isNotEmpty) {
                  imageWidget = Image.memory(
                    base64Decode(data['imagePath']),
                    fit: BoxFit.cover,
                  );
                } else {
                  imageWidget = const Icon(Icons.fastfood, color: Colors.grey);
                }
              } catch (e) {
                imageWidget = const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                );
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageWidget,
                    ),
                  ),
                  title: Text(
                    data['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "RM ${(data['price'] ?? 0).toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Qty: ${data['quantity']}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed:
                            () => _showAddEditDialog(
                              context,
                              merchantId: merchantId,
                              docId: itemId,
                              currentData: data,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () => _deleteItem(context, merchantId, itemId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context, {
    required String merchantId,
    String? docId,
    Map<String, dynamic>? currentData,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => _FoodDialog(
            merchantId: merchantId,
            docId: docId,
            currentData: currentData,
          ),
    );
  }

  void _deleteItem(BuildContext context, String merchantId, String itemId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Delete Item?"),
            content: const Text("This cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              TextButton(
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('merchants')
                      .doc(merchantId)
                      .collection('items')
                      .doc(itemId)
                      .delete();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
    );
  }
}

// ✅ Separate Widget for Dialog to handle State
class _FoodDialog extends StatefulWidget {
  final String merchantId;
  final String? docId;
  final Map<String, dynamic>? currentData;

  const _FoodDialog({required this.merchantId, this.docId, this.currentData});

  @override
  State<_FoodDialog> createState() => _FoodDialogState();
}

class _FoodDialogState extends State<_FoodDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();
  bool _showImageError = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentData?['name'] ?? '');
    _priceCtrl = TextEditingController(
      text: widget.currentData?['price']?.toString() ?? '',
    );
    _qtyCtrl = TextEditingController(
      text: widget.currentData?['quantity']?.toString() ?? '1',
    );
    _base64Image = widget.currentData?['imagePath'];
  }

  Future<void> _pickImage() async {
    // ✅ STRICTLY GALLERY
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
        _showImageError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.docId == null ? "Add New Food" : "Edit Food"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE PICKER
            const Text(
              "Food Photo (Required)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showImageError ? Colors.red : Colors.grey[400]!,
                    width: _showImageError ? 2 : 1,
                  ),
                ),
                child:
                    _base64Image != null && _base64Image!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(
                            base64Decode(_base64Image!),
                            fit: BoxFit.cover,
                          ),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: _showImageError ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap to pick from Album",
                              style: TextStyle(
                                color:
                                    _showImageError
                                        ? Colors.red
                                        : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            if (_showImageError)
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  "Image is required!",
                  style: TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),

            const SizedBox(height: 20),

            // FIELDS
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Food Name",
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: "Price (RM)",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(
                labelText: "Quantity Available",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            final price = double.tryParse(_priceCtrl.text) ?? 0.0;
            final qty = int.tryParse(_qtyCtrl.text) ?? 0;

            // ✅ VALIDATION: Image is MUST
            if (name.isEmpty ||
                price <= 0 ||
                qty <= 0 ||
                _base64Image == null) {
              setState(() {
                if (_base64Image == null) _showImageError = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please fill all fields and choose a photo!"),
                ),
              );
              return;
            }

            final data = {
              'name': name,
              'price': price,
              'quantity': qty,
              'imagePath': _base64Image,
              'merchantId': widget.merchantId,
            };

            if (widget.docId == null) {
              await FirebaseFirestore.instance
                  .collection('merchants')
                  .doc(widget.merchantId)
                  .collection('items')
                  .add(data);
            } else {
              await FirebaseFirestore.instance
                  .collection('merchants')
                  .doc(widget.merchantId)
                  .collection('items')
                  .doc(widget.docId)
                  .update(data);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("Save Item"),
        ),
      ],
    );
  }
}
