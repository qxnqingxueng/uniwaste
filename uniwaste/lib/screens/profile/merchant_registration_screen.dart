import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MerchantRegistrationScreen extends StatefulWidget {
  const MerchantRegistrationScreen({super.key});

  @override
  State<MerchantRegistrationScreen> createState() =>
      _MerchantRegistrationScreenState();
}

class _MerchantRegistrationScreenState
    extends State<MerchantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerMerchant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Create the Merchant Profile in 'merchants' collection
      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(user.uid)
          .set({
            // ✅ CRITICAL: Public Fields (Read by Marketplace)
            'id': user.uid,
            'name':
                _shopNameController.text.trim(), // Marketplace looks for 'name'
            'description':
                _shopAddressController.text
                    .trim(), // Marketplace looks for 'description'
            'imageUrl': '', // Placeholder until they add a photo
            'rating': 5.0,
            'isOpen': true,

            // ✅ Internal Fields (Read by Dashboard)
            'shopName': _shopNameController.text.trim(),
            'shopAddress': _shopAddressController.text.trim(),
            'phone': _phoneController.text.trim(),
            'ownerEmail': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 2. Update the User's Role in 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'role': 'merchant'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Congratulations! You are now a Merchant."),
          ),
        );
        Navigator.pop(context, true); // Return true to reload profile
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
      appBar: AppBar(title: const Text("Merchant Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Partner with UniWaste",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Turn your surplus food into revenue and save the planet.",
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  labelText: "Shop / Restaurant Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Business Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _shopAddressController,
                decoration: const InputDecoration(
                  labelText: "Shop Address (e.g. Canteen A)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerMerchant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Register Shop"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
