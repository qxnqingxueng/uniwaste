import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MerchantSettingsScreen extends StatefulWidget {
  const MerchantSettingsScreen({super.key});

  @override
  State<MerchantSettingsScreen> createState() => _MerchantSettingsScreenState();
}

class _MerchantSettingsScreenState extends State<MerchantSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _deliveryFeeController = TextEditingController();

  // Image
  String? _currentBase64Image;
  final ImagePicker _picker = ImagePicker();

  // Category Logic
  final List<String> _allOptions = [
    'Halal',
    'Vegetarian',
    'No Pork',
    'Cheap Eats',
  ];
  List<String> _selectedCategories = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('merchants')
              .doc(user.uid)
              .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? data['shopName'] ?? '';

          // Fix: Ensure address is loaded into address controller
          _addressController.text =
              data['address'] ?? data['shopAddress'] ?? '';

          _descController.text = data['description'] ?? '';
          _phoneController.text = data['phone'] ?? '';

          // ✅ Fix: Handle potential number types safely
          var fee = data['deliveryFee'];
          if (fee is int) {
            _deliveryFeeController.text = fee.toDouble().toStringAsFixed(2);
          } else if (fee is double) {
            _deliveryFeeController.text = fee.toStringAsFixed(2);
          } else {
            _deliveryFeeController.text = "3.00"; // Default
          }

          _deliveryTimeController.text = data['deliveryTime'] ?? '25 mins';
          _currentBase64Image = data['imageUrl'];

          if (data['categories'] != null) {
            _selectedCategories = List<String>.from(data['categories']);
          } else {
            _selectedCategories = [];
          }

          _isLoading = false;
        });
      } else {
        // Document doesn't exist yet, just stop loading
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _currentBase64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Allow saving without image if you want, or keep strict validation
    if (_currentBase64Image == null || _currentBase64Image!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Shop image is required!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      double deliveryFee = double.tryParse(_deliveryFeeController.text) ?? 3.00;

      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(user!.uid)
          .set({
            // Using set with merge: true is safer if doc might not exist
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim(), // ✅ Save Address
            'description': _descController.text.trim(),
            'phone': _phoneController.text.trim(),
            'imageUrl': _currentBase64Image,
            'categories': _selectedCategories,
            'deliveryFee': deliveryFee,
            'deliveryTime': _deliveryTimeController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Shop settings updated!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Settings")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[400]!),
                              image:
                                  _currentBase64Image != null &&
                                          _currentBase64Image!.isNotEmpty
                                      ? DecorationImage(
                                        image: MemoryImage(
                                          base64Decode(_currentBase64Image!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                _currentBase64Image == null
                                    ? const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_a_photo),
                                          Text("Add Shop Photo"),
                                        ],
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Shop Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),

                      // ✅ Added Address Field back
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: "Shop Address",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _deliveryFeeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Delivery Fee (RM)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.delivery_dining),
                          helperText: "This fee applies to all delivery orders",
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          if (double.tryParse(v) == null)
                            return "Invalid number";
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // ✅ Ensure this is wrapped in a way it doesn't error if expanded isn't needed
                      TextFormField(
                        controller: _deliveryTimeController,
                        decoration: const InputDecoration(
                          labelText: "Est. Time",
                          border: OutlineInputBorder(),
                          hintText: "e.g. 30 mins",
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const Text(
                        "Category Tags",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8.0,
                        children:
                            _allOptions.map((category) {
                              final isSelected = _selectedCategories.contains(
                                category,
                              );
                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                selectedColor: Colors.green[100],
                                checkmarkColor: Colors.green,
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const Divider(),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text("Save Changes"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
