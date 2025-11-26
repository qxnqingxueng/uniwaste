import 'package:flutter/material.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Waste Management',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('UniWaste Home'),
        ),
        body: const Center(
          child: Text('Welcome to UniWaste!'),
        ),
      ),
    );
  }
}
