import 'package:flutter/material.dart';

class ExitScreen extends StatelessWidget {
  const ExitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Fermer l'application ou retourner à une page précédente.
          },
          child: const Text('Quitter'),
        ),
      ),
    );
  }
}
