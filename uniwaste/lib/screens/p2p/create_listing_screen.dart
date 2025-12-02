import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  // Image Data
  File? _imageFile;
  Uint8List? _imageBytes; // For Blob storage
  File? _proofImageFile; // For packaged food expiry proof
  Uint8List? _proofImageBytes;

  // Form State
  String _foodType = 'cooked'; // 'cooked' or 'packaged'
  bool _isFree = true;
  DateTime? _expiryDate;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // --- Image Handling ---
  Future<void> _pickImage({bool isProof = false}) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 600, // Optimize size for DB storage
      imageQuality: 70, // Compress to save space
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isProof) {
          _proofImageFile = File(pickedFile.path);
          _proofImageBytes = bytes;
        } else {
          _imageFile = File(pickedFile.path);
          _imageBytes = bytes;
        }
      });
    }
  }

  // --- Expiry Logic ---
  void _updateExpiryLogic(String type) {
    setState(() {
      _foodType = type;
      if (type == 'cooked') {
        // Auto-set 12 hours for safety
        _expiryDate = DateTime.now().add(const Duration(hours: 12));
      } else {
        // Reset for manual input
        _expiryDate = null;
      }
    });
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      // Optional: Add TimePicker
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  // --- Submit to Firestore ---
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image of the food.')),
      );
      return;
    }
    if (_foodType == 'packaged' && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set an expiry date for packaged goods.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthenticationBloc>().state.user;
      final db = FirebaseFirestore.instance;

      // Create Payload
      final Map<String, dynamic> p2pData = {
        'donor_id': user?.userId ?? 'unknown',
        'donor_name': user?.name ?? 'Anonymous',
        'description': _descriptionController.text,
        'food_type': _foodType,
        'is_free': _isFree,
        'price': _isFree ? 0 : double.tryParse(_priceController.text) ?? 0,
        'expiry_date': _expiryDate,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'available',
        'image_blob': Blob(_imageBytes!), 
      };

      // Add proof blob if packaged
      if (_foodType == 'packaged' && _proofImageBytes != null) {
        p2pData['expiry_proof_blob'] = Blob(_proofImageBytes!);
      }

      await db.collection('food_listings').add(p2pData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing Posted Successfully!')),
        );
        Navigator.pop(context); // Go back to dashboard/P2P page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donate / Sell Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Image Picker
              GestureDetector(
                onTap: () => _pickImage(isProof: false),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!), // Display bytes directly
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            Text("Tap to upload food photo"),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description (e.g., Fried Rice, Canned Beans)",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // 3. Food Type
              DropdownButtonFormField<String>(
                value: _foodType,
                decoration: const InputDecoration(labelText: "Food Type", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'cooked', child: Text("Cooked Meal")),
                  DropdownMenuItem(value: 'packaged', child: Text("Packaged Goods")),
                ],
                onChanged: (val) {
                  if (val != null) _updateExpiryLogic(val);
                },
              ),
              const SizedBox(height: 16),

              // 4. Expiry Info
              if (_foodType == 'cooked')
                const Card(
                  color: Color.fromRGBO(210, 220, 182, 0.5),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.black54),
                        SizedBox(width: 8),
                        Expanded(child: Text("Cooked meals expire automatically in 12 hours.")),
                      ],
                    ),
                  ),
                )
              else ...[
                // Manual Expiry Date Picker for Packaged
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_expiryDate == null 
                    ? "Select Expiry Date" 
                    : "Expires: ${_expiryDate.toString().split(' ')[0]}"
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectExpiryDate,
                ),
                // Expiry Proof Image
                const Text("Upload Expiry Date Proof (on package):", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _pickImage(isProof: true),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: _proofImageBytes != null 
                      ? Image.memory(_proofImageBytes!, fit: BoxFit.cover)
                      : const Center(child: Text("Tap to upload proof")),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Price / Free
              Row(
                children: [
                  Checkbox(
                    value: _isFree,
                    onChanged: (val) => setState(() => _isFree = val!),
                  ),
                  const Text("List for Free"),
                ],
              ),
              if (!_isFree)
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Price (RM)",
                    border: OutlineInputBorder(),
                    prefixText: "RM ",
                  ),
                  validator: (val) => (!_isFree && (val == null || val.isEmpty)) ? 'Enter price' : null,
                ),
              const SizedBox(height: 24),

              // 6. Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Post Listing"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}