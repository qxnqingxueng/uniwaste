import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/widgets/animated_check.dart'; 

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  File? _imageFile;
  Uint8List? _imageBytes;
  File? _proofImageFile;
  Uint8List? _proofImageBytes;

  String _foodType = 'cooked';
  bool _isFree = true;
  DateTime? _expiryDate;
  bool _isLoading = false;

  // ✅ RESTRICTION STATE
  bool _checkingRestriction = true;
  bool _isRestricted = false;
  String _restrictionMessage = "";

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkUserRestriction();
    _updateExpiryLogic('cooked');
  }

  // --- 1. CHECK RESTRICTION LOGIC ---
  Future<void> _checkUserRestriction() async {
    final uid = context.read<AuthenticationBloc>().state.user?.userId;
    if (uid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        
        // ✅ NEW LOGIC: Only restrict if Admin has set a ban timestamp
        final Timestamp? banExpiresAt = data['banExpiresAt'];

        if (banExpiresAt != null) {
          final DateTime expiryDate = banExpiresAt.toDate();
          if (expiryDate.isAfter(DateTime.now())) {
             // User is banned
             final int daysLeft = expiryDate.difference(DateTime.now()).inDays + 1;
             
             if (mounted) {
               setState(() {
                 _isRestricted = true;
                 _restrictionMessage = "Restricted for $daysLeft more days.";
               });
             }
             return;
          }
        }
        
        // We do NOT block automatically based on score/reports anymore.
        // That is now handled by Admin via the dashboard.
      }
    } catch (e) {
      debugPrint("Error checking restriction: $e");
    } finally {
      if (mounted) setState(() => _checkingRestriction = false);
    }
  }

  // --- Image Picking ---
  Future<void> _pickImage({bool isProof = false}) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 70,
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
        _expiryDate = DateTime.now().add(const Duration(hours: 12));
      } else {
        _expiryDate = null;
      }
    });
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      _expiryDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
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
        const SnackBar(
          content: Text('Please set an expiry date for packaged goods.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthenticationBloc>().state.user;
      final db = FirebaseFirestore.instance;

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

      if (_foodType == 'packaged' && _proofImageBytes != null) {
        p2pData['expiry_proof_blob'] = Blob(_proofImageBytes!);
      }

      await db.collection('food_listings').add(p2pData);

      if (mounted) {
        // ✅ REPLACED SNACKBAR WITH ANIMATED CHECK DIALOG
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const AnimatedCheck(size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Listing Posted!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Thank you for sharing with the community.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                },
                child: const Text("OK", style: TextStyle(color: Color(0xFF6B8E23))),
              ),
            ],
          ),
        );
        
        // After dialog closes, pop the screen
        if (mounted) {
           Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingRestriction) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🚨 RESTRICTED UI 🚨
    if (_isRestricted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Access Restricted"),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Account Suspended",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _restrictionMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                
                // Contact info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        "Please contact the admin for appeals:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text("admin@uniwaste.com", style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Go Back", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal Form UI
    return Scaffold(
      appBar: AppBar(title: const Text("Donate / Sell Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => _pickImage(isProof: false),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!),
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
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _foodType,
                decoration: const InputDecoration(
                  labelText: "Food Type",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cooked', child: Text("Cooked Meal")),
                  DropdownMenuItem(value: 'packaged', child: Text("Packaged Goods")),
                ],
                onChanged: (val) {
                  if (val != null) _updateExpiryLogic(val);
                },
              ),
              const SizedBox(height: 16),
              if (_foodType == 'cooked')
                const Card(
                  color: Color.fromRGBO(210, 220, 182, 0.5),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Cooked meals expire automatically in 12 hours.",
                    ),
                  ),
                )
              else ...[
                ListTile(
                  title: Text(
                    _expiryDate == null
                        ? "Select Expiry Date"
                        : "Expires: ${_expiryDate.toString().split(' ')[0]}",
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectExpiryDate,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _pickImage(isProof: true),
                  child: Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: _proofImageBytes != null
                        ? Image.memory(_proofImageBytes!, fit: BoxFit.cover)
                        : const Center(child: Text("Tap to upload proof")),
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
                    prefixText: "RM ",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      (!_isFree && (val == null || val.isEmpty)) ? 'Enter price' : null,
                ),
              const SizedBox(height: 24),
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