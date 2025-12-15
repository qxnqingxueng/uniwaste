import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uniwaste/screens/merchant/add_menu_item_screen.dart';

class MerchantMenuScreen extends StatefulWidget {
  const MerchantMenuScreen({super.key});

  @override
  State<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends State<MerchantMenuScreen> {
  String? _merchantId;

  @override
  void initState() {
    super.initState();
    _fetchMerchantId();
  }

  Future<void> _fetchMerchantId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (mounted) {
        setState(() {
          _merchantId = doc.data()?['merchantId'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_merchantId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Management"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMenuItemScreen()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('merchants')
                .doc(_merchantId)
                .collection('menu')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No items yet. Add one!"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              // Handle image decoding
              ImageProvider? imageProvider;
              if (data['image'] != null) {
                try {
                  imageProvider = MemoryImage(base64Decode(data['image']));
                } catch (e) {
                  // Fallback
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      image:
                          imageProvider != null
                              ? DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        imageProvider == null
                            ? const Icon(Icons.fastfood)
                            : null,
                  ),
                  title: Text(data['title']),
                  subtitle: Text(
                    "Qty: ${data['surplus']} | RM ${data['price']}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('merchants')
                          .doc(_merchantId)
                          .collection('menu')
                          .doc(id)
                          .delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
