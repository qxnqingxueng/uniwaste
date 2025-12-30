import 'dart:io';
import 'dart:convert'; // for base64Encode / base64Decode
import 'dart:typed_data'; // for Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/profile/voucher_screen.dart';
import 'package:uniwaste/screens/profile/activity_screen.dart';
import 'package:uniwaste/screens/profile/merchant_registration_screen.dart';
import 'package:uniwaste/screens/merchant/dashboard/merchant_dashboard_screen.dart';
import 'package:uniwaste/screens/profile/company_registration_screen.dart';
import 'package:uniwaste/screens/waste-to-resources/company/company_dashboard_screen.dart';
import 'package:uniwaste/screens/admin/admin_report_screen.dart';
import 'package:uniwaste/screens/profile/address_book_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Profile fields
  String _name = '';
  String _gender = '';
  String _email = '';
  String _address = '';
  int _points = 0;
  String _role = 'student'; // Default role

  // NEW FIELD: Reputation Score
  double _reputationScore = 100.0;

  // we store the avatar as bytes in memory
  Uint8List? _photoBytes;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ------------ LOAD FROM FIREBASE ------------
  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      _email = user.email ?? '';

      final docRef = _firestore.collection('users').doc(user.uid);
      final snap = await docRef.get();

      if (snap.exists) {
        final data = snap.data()!;
        _name = (data['name'] ?? '') as String;
        _gender = (data['gender'] ?? '') as String;
        _address = (data['address'] ?? '') as String;
        _role = (data['role'] ?? 'student') as String;

        // read base64 avatar if exists
        final photoBase64 = data['photoBase64'] as String?;
        if (photoBase64 != null && photoBase64.isNotEmpty) {
          try {
            _photoBytes = base64Decode(photoBase64);
          } catch (e) {
            debugPrint("Error decoding image: $e");
          }
        }

        // read points
        final pointsData = data['points'];
        if (pointsData is int) {
          _points = pointsData;
        } else if (pointsData is num) {
          _points = pointsData.toInt();
        } else {
          _points = 0;
        }

        // READ REPUTATION
        final scoreData = data['reputationScore'];
        if (scoreData is num) {
          _reputationScore = scoreData.toDouble();
        } else {
          _reputationScore = 100.0; // Default if missing
        }
      } else {
        // Create default doc if missing
        await docRef.set({
          'email': _email,
          'name': '',
          'gender': '',
          'address': '',
          'photoBase64': '',
          'points': 0,
          'reputationScore': 100.0, // Default
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // generic field update
  Future<void> _updateField(String field, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating $field: $e');
    }
  }

  // ------------ PICK & "UPLOAD" IMAGE (BASE64) ------------
  Future<void> _pickImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 500, // Optimize size
    );

    if (picked == null) return;

    // confirm
    final bool? confirmed = await _showConfirmChangeDialog('profile picture');
    if (confirmed != true) return;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();

    // update UI immediately
    setState(() {
      _photoBytes = bytes;
    });

    // convert to Base64 text
    final base64Str = base64Encode(bytes);

    // save into Firestore
    await _updateField('photoBase64', base64Str);
  }

  // ------------ UI BUILD ------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F3E0), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'My Profile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // PROFILE PICTURE
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFA1BC98),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(child: _buildProfileImage()),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFA1BC98),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildImpactBanner(context),
                const SizedBox(height: 28),

                // PROFILE INFO CARD
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // NAME
                      _buildProfileItem(
                        icon: Icons.person,
                        label: 'Name',
                        value: _name.isEmpty ? 'Tap to add your name' : _name,
                        onTap:
                            () => _showEditDialog(
                              title: 'Edit Name',
                              fieldName: 'name',
                              currentValue: _name,
                              onConfirm: (value) {
                                setState(() => _name = value);
                                _updateField('name', value);
                              },
                            ),
                      ),
                      _buildDivider(),

                      // GENDER
                      _buildProfileItem(
                        icon: Icons.wc,
                        label: 'Gender',
                        value: _gender.isEmpty ? 'Not set' : _gender,
                        onTap: _showGenderDialog,
                      ),
                      _buildDivider(),

                      // EMAIL (read-only)
                      _buildProfileItem(
                        icon: Icons.email,
                        label: 'Email',
                        value: _email,
                        onTap: () {}, // no action
                        showChevron: false,
                      ),
                      _buildDivider(),

                      // ADDRESS
                      _buildProfileItem(
                        icon: Icons.location_on,
                        label: 'Address',
                        value:
                            _address.isEmpty ? 'Tap to select block' : _address,
                        onTap: _showAddressDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ACTIONS CARD (vouchers, activity)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildActionItem(
                        icon: Icons.local_activity,
                        label: 'Vouchers',
                        iconColor: const Color(0xFFA1BC98),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VoucherScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildActionItem(
                        icon: Icons.history,
                        label: 'My Activity',
                        iconColor: const Color(0xFFD2DCB6),
                        onTap: () {
                          final user = _auth.currentUser;
                          if (user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ActivityScreen(userId: user.uid),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- MERCHANT SECTION ---
                _buildMerchantSection(),

                const SizedBox(height: 20),

                // --- COMPANY SECTION ---
                _buildCompanySection(),

                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.red,
                  ),
                  title: const Text("Admin Panel"),
                  onTap: () {
                    // ✅ Fixed: Removed duplicate MaterialPageRoute
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminReportScreen(),
                      ),
                    );
                  },
                ),

                // LOGOUT BUTTON
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------ SMALL HELPERS ------------

  Widget _buildProfileImage() {
    if (_photoBytes != null) {
      return Image.memory(
        _photoBytes!,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
      );
    } else {
      // Fallback or placeholder
      return Container(
        width: 110,
        height: 110,
        color: Colors.grey[200],
        child: const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    }
  }

  // UPDATED BANNER: SHOW REPUTATION
  Widget _buildImpactBanner(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Color logic for score
    Color scoreColor = Colors.white;
    if (_reputationScore < 50) {
      scoreColor = Colors.redAccent;
    } else if (_reputationScore < 80)
      scoreColor = Colors.amberAccent;

    return SizedBox(
      width: width * 0.88,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFA1BC98),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Impact',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_points points earned 🌱',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '“Every meal saved is one less in the bin.”',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),

            // REPUTATION SECTION
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Reputation: ",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  _reputationScore.toStringAsFixed(1),
                  // ✅ Fixed: Removed duplicate properties
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  " / 100",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Merchant Section ---
  Widget _buildMerchantSection() {
    // Check roles
    final isMerchant = _role == 'merchant';
    final isCompany = _role == 'company';

    // If user is a Company, this button should be disabled (cannot trigger)
    final bool isDisabled = isCompany;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        // If disabled, show grey background
        color:
            isDisabled
                ? Colors.grey.shade200
                : (isMerchant ? Colors.orange.shade50 : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // If disabled, show grey border
          color:
              isDisabled
                  ? Colors.grey.shade400
                  : (isMerchant
                      ? Colors.orange.shade200
                      : Colors.blue.shade200),
        ),
      ),
      child: InkWell(
        // If disabled, onTap is null (button doesn't work)
        onTap:
            isDisabled
                ? null
                : () async {
                  if (isMerchant) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MerchantDashboardScreen(),
                      ),
                    );
                  } else {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const MerchantRegistrationScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadUserProfile();
                    }
                  }
                },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                isMerchant ? Icons.store : Icons.storefront_outlined,
                color:
                    isDisabled
                        ? Colors.grey
                        : (isMerchant ? Colors.orange : Colors.blue),
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDisabled
                          ? 'Merchant Option Unavailable'
                          : (isMerchant
                              ? 'Merchant Dashboard'
                              : 'Become a Merchant'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isDisabled
                                ? Colors.grey.shade600
                                : (isMerchant
                                    ? Colors.orange.shade900
                                    : Colors.blue.shade900),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDisabled
                          ? 'You are registered as a Company'
                          : (isMerchant
                              ? 'Manage menu & orders'
                              : 'For official campus vendors'),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDisabled
                                ? Colors.grey.shade500
                                : (isMerchant
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color:
                    isDisabled
                        ? Colors.grey
                        : (isMerchant ? Colors.orange : Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Company Section---
  Widget _buildCompanySection() {
    // Check roles
    final isCompany = _role == 'company';
    final isMerchant = _role == 'merchant';

    // If user is a Merchant, this button should be disabled
    final bool isDisabled = isMerchant;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        // If disabled, show grey background
        color:
            isDisabled
                ? Colors.grey.shade200
                : (isCompany ? Colors.orange.shade50 : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDisabled
                  ? Colors.grey.shade400
                  : (isCompany ? Colors.orange.shade200 : Colors.blue.shade200),
        ),
      ),
      child: InkWell(
        onTap:
            isDisabled
                ? null
                : () async {
                  if (isCompany) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyDashboardScreen(),
                      ),
                    );
                  } else {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompanyRegistrationScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadUserProfile();
                    }
                  }
                },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                isCompany ? Icons.business : Icons.business,
                color:
                    isDisabled
                        ? Colors.grey
                        : (isCompany ? Colors.orange : Colors.blue),
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDisabled
                          ? 'Company Option Unavailable'
                          : (isCompany
                              ? 'Company Registered'
                              : 'Become a Company'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isDisabled
                                ? Colors.grey.shade600
                                : (isCompany
                                    ? Colors.orange.shade900
                                    : Colors.blue.shade900),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDisabled
                          ? 'You are registered as a Merchant'
                          : (isCompany
                              ? 'Corporate partner status active'
                              : 'For corporate partners'),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDisabled
                                ? Colors.grey.shade500
                                : (isCompany
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color:
                    isDisabled
                        ? Colors.grey
                        : (isCompany ? Colors.orange : Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFA1BC98), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron) Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }

  // ------------ DIALOGS ------------

  Future<bool?> _showConfirmChangeDialog(String fieldName) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirm Change'),
          content: Text('Are you sure you want to change your $fieldName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes, change it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog({
    required String title,
    required String fieldName,
    required String currentValue,
    required ValueChanged<String> onConfirm,
  }) async {
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) return;

                Navigator.of(dialogContext).pop();

                final confirmed = await _showConfirmChangeDialog(fieldName);
                if (confirmed == true) {
                  onConfirm(value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGenderDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Select Gender'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          children: [
            for (final option in ['Male', 'Female', 'Rather not say'])
              SimpleDialogOption(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final confirmed = await _showConfirmChangeDialog('gender');
                  if (confirmed == true) {
                    setState(() => _gender = option);
                    _updateField('gender', option);
                  }
                },
                child: Text(option),
              ),
          ],
        );
      },
    );
  }

  // UPDATED ADDRESS DIALOG LOGIC
  Future<void> _showAddressDialog() async {
    // Navigate to the full Address Book
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressBookScreen()),
    );
    // Reload profile when back to reflect changes if default changed
    _loadUserProfile();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthenticationBloc>().add(
                  AuthenticationLogoutRequested(),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
