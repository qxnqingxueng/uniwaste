import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddressBookScreen extends StatefulWidget {
  final bool selectMode; // If true, we return the data on back press
  const AddressBookScreen({super.key, this.selectMode = false});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final _addressController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // Track the selected address locally to return it when Back is pressed
  String? _selectedAddressToReturn;

  // Add a new address
  Future<void> _addAddress() async {
    final text = _addressController.text.trim();
    if (text.isEmpty || _uid == null) return;

    final userRef = _db.collection('users').doc(_uid);

    final snap = await userRef.get();
    final currentAddress = snap.data()?['address'] as String? ?? '';

    await userRef.update({
      'savedAddresses': FieldValue.arrayUnion([text]),
      // Auto-set default if none exists
      if (currentAddress.isEmpty) 'address': text,
    });

    _addressController.clear();
    if (mounted) Navigator.pop(context);
  }

  // Set as Default (Turns Green)
  Future<void> _setAsDefault(String address) async {
    if (_uid == null) return;

    // 1. Update Firestore (This triggers the StreamBuilder to rebuild and show Green)
    await _db.collection('users').doc(_uid).update({'address': address});

    // 2. Track this selection to return it when user clicks Back
    setState(() {
      _selectedAddressToReturn = address;
    });

    // NOTE: We do NOT pop here anymore. User must click Back manually.
  }

  // Delete Address
  Future<void> _deleteAddress(String address, String currentDefault) async {
    if (_uid == null) return;

    final userRef = _db.collection('users').doc(_uid);
    final batch = _db.batch();

    batch.update(userRef, {
      'savedAddresses': FieldValue.arrayRemove([address]),
    });

    if (address == currentDefault) {
      batch.update(userRef, {'address': ''});
    }

    await batch.commit();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Add New Address"),
            content: TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: "e.g., Block A, Room 123, UniWaste Hostel",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _addAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA1BC98),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null)
      return const Scaffold(body: Center(child: Text("Please login")));

    // Handle System Back Button (Android)
    return PopScope(
      canPop: false, // We handle the pop manually
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Return the selected address (or null if none selected)
        Navigator.pop(context, _selectedAddressToReturn);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.selectMode ? "Select Delivery Address" : "My Addresses",
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          // Custom Back Button
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Return the chosen address to Checkout Page
              Navigator.pop(context, _selectedAddressToReturn);
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: const Color(0xFFA1BC98),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _db.collection('users').doc(_uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final currentDefault = data['address'] as String? ?? '';

            List<String> addresses = List<String>.from(
              data['savedAddresses'] ?? [],
            );

            if (currentDefault.isNotEmpty &&
                !addresses.contains(currentDefault)) {
              addresses.insert(0, currentDefault);
            }

            if (addresses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text("No saved addresses yet."),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                final isDefault = addr == currentDefault;

                return Card(
                  elevation: 0,
                  // GREEN if Default
                  color: isDefault ? const Color(0xFFF1F3E0) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          isDefault
                              ? const Color(0xFFA1BC98)
                              : Colors.grey.shade200,
                      width: isDefault ? 2 : 1,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      addr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle:
                        isDefault
                            ? const Text(
                              "Default Address",
                              style: TextStyle(
                                color: Color(0xFFA1BC98),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                    leading: Icon(
                      isDefault
                          ? Icons.check_circle
                          : Icons.location_on_outlined,
                      color: isDefault ? const Color(0xFFA1BC98) : Colors.grey,
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder:
                          (ctx) => [
                            // Even if not default, we have 'Set as Default' in menu too
                            if (!isDefault)
                              const PopupMenuItem(
                                value: 'default',
                                child: Text("Set as Default"),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                      onSelected: (val) {
                        if (val == 'default') _setAsDefault(addr);
                        if (val == 'delete')
                          _deleteAddress(addr, currentDefault);
                      },
                    ),
                    onTap: () {
                      // ✅ Always set as default (turns green), do NOT auto-pop
                      _setAsDefault(addr);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
