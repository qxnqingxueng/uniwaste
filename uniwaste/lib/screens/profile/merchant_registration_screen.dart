import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class MerchantRegistrationScreen extends StatefulWidget {
  const MerchantRegistrationScreen({super.key});

  @override
  State<MerchantRegistrationScreen> createState() =>
      _MerchantRegistrationScreenState();
}

class _MerchantRegistrationScreenState
    extends State<MerchantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  Uint8List? _shopImageBytes; // Store image in memory
  final ImagePicker _picker = ImagePicker();

  // Pick Image Logic
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        _shopImageBytes = bytes;
      });
    }
  }

  // Submit Logic
  Future<void> _registerMerchant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_shopImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a shop image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Generate Merchant ID
      final merchantId = const Uuid().v4();
      final base64Image = base64Encode(
        _shopImageBytes!,
      ); // Storing image as string for simplicity

      // 2. Create Merchant Document
      await FirebaseFirestore.instance.collection('merchants').doc(merchantId).set({
        'id': merchantId,
        'ownerId': user.uid,
        'name': _shopNameController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'image':
            base64Image, // In a real app, upload to Firebase Storage and save URL
        'rating': 5.0, // Start with default rating
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update User Role to 'merchant'
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'role': 'merchant', 'merchantId': merchantId},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration Successful! Welcome, Partner."),
          ),
        );
        Navigator.pop(context, true); // Return 'true' to indicate success
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Become a Merchant"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Official Merchants Only. Students selling P2P items should use the Student Feed.",
                        style: TextStyle(fontSize: 12, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                      image:
                          _shopImageBytes != null
                              ? DecorationImage(
                                image: MemoryImage(_shopImageBytes!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        _shopImageBytes == null
                            ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.store, size: 40, color: Colors.grey),
                                Text("Tap to upload Shop Logo"),
                              ],
                            )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  labelText: "Shop Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Campus Location (e.g. KK12)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description / Food Type",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _registerMerchant,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Register Shop",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
