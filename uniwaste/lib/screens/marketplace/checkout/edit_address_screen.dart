import 'package:flutter/material.dart';
import 'package:uniwaste/screens/marketplace/checkout/models/delivery_info.dart';

class EditAddressScreen extends StatefulWidget {
  final DeliveryInfo currentInfo;
  const EditAddressScreen({super.key, required this.currentInfo});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentInfo.name);
    _phoneController = TextEditingController(text: widget.currentInfo.phone);
    _addressController = TextEditingController(
      text: widget.currentInfo.address,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Address",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Address"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  DeliveryInfo(
                    name: _nameController.text,
                    phone: _phoneController.text,
                    address: _addressController.text,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
