import 'package:flutter/material.dart';

class P2PStudentPage extends StatelessWidget {
  const P2PStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
                'P2P Student',
                style: TextStyle(fontSize: 20, color: Colors.black),
            ),
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        foregroundColor: Colors.black, // Makes the back button black
        
        elevation: 0,

        leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
        onPressed: () {
          Navigator.pop(context); 
        },
      ),
      ),

      body: const Center(
        child: Text(
          'P2P Student Page',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      ),
    );
  }
}