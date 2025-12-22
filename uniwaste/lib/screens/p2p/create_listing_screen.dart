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

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkUserRestriction(); // Check immediately on load
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
        final int reports = (data['reportCount'] ?? 0) as int;

        // Handle potentially different number types from Firestore
        final double score =
            (data['reputationScore'] is int)
                ? (data['reputationScore'] as int).toDouble()
                : (data['reputationScore'] as double? ?? 100.0);

        // 🚨 Rule: 3+ Reports OR Score < 50
        if (reports >= 3 || score < 50.0) {
          if (mounted) setState(() => _isRestricted = true);
        }
      }
    } catch (e) {
      debugPrint("Error checking restriction: $e");
    } finally {
      if (mounted) setState(() => _checkingRestriction = false);
    }
  }

  // --- 2. IMMEDIATE RESET LOGIC (No Admin) ---
  Future<void> _submitAppeal() async {
    final uid = context.read<AuthenticationBloc>().state.user?.userId;
    if (uid == null) return;

    // Confirm with user
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("Reset Account Status"),
                content: const Text(
                  "Since there is no admin, this will immediately reset your Reputation Score to 100 and clear your Report Count.\n\nDo you want to proceed?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B8E23),
                    ),
                    child: const Text(
                      "Reset & Unblock",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      // ✅ RESET DATABASE FIELDS DIRECTLY
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'reportCount': 0,
        'reputationScore': 100.0,
        'last_reset_at': FieldValue.serverTimestamp(), // Optional: Audit trail
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account status reset! You can now post listings."),
          ),
        );

        // ✅ UNBLOCK UI IMMEDIATELY
        setState(() {
          _isRestricted = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error resetting account: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing Posted Successfully!')),
        );
        Navigator.pop(context);
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
    // 1. Loading
    if (_checkingRestriction) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. 🚨 RESTRICTED UI (With Reset Button) 🚨
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
                  Icons.gpp_bad_outlined,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Posting Restricted",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Your account is restricted due to low reputation or reports.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // ✅ RESET BUTTON
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                      onPressed: _submitAppeal,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset Account Status"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B8E23),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Go Back",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Normal Form UI
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
                    image:
                        _imageBytes != null
                            ? DecorationImage(
                              image: MemoryImage(_imageBytes!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _imageBytes == null
                          ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
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
                  DropdownMenuItem(
                    value: 'packaged',
                    child: Text("Packaged Goods"),
                  ),
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
                    child:
                        _proofImageBytes != null
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
                  validator:
                      (val) =>
                          (!_isFree && (val == null || val.isEmpty))
                              ? 'Enter price'
                              : null,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(119, 136, 115, 1.0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
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
