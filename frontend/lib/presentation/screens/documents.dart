import 'package:flutter/material.dart';

class Documents extends StatelessWidget {
  const Documents({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: const Center(
        child: Text('Liste des documents disponibles.'),
      ),
    );
  }
}
