import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  State<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _registrationNumberController = TextEditingController(); // [ADDED]
  final _companyAddressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Create the Company Profile
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.uid)
          .set({
            'id': user.uid,
            'name': _companyNameController.text.trim(),
            'registrationNumber':
                _registrationNumberController.text.trim(), // [ADDED]
            'address': _companyAddressController.text.trim(),
            'phone': _phoneController.text.trim(),
            'ownerEmail': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 2. Update the User's Role
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'role': 'company',
          'name':
              _companyNameController.text.trim(), // Update name to Company Name
        },
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap OK
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Registration Successful!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "🎉 Congratulations! You are now registered as a Company.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Close Dialog
                        Navigator.pop(context, true); // Return to Profile
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(
                          119,
                          136,
                          115,
                          1.0,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("OK"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
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
      appBar: AppBar(title: const Text("Company Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Register as a Company",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join UniWaste to manage large scale waste solutions.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

              // 1. Registered Name
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: "Registered Company Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 2. Registration Number (Numpad Only)
              TextFormField(
                controller: _registrationNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Company Registration Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 3. Contact Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Business Contact Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 4. Address
              TextFormField(
                controller: _companyAddressController,
                decoration: const InputDecoration(
                  labelText: "Company Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerCompany,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Register Company"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
