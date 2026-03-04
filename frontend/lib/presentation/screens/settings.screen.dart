import 'package:flutter/material.dart';
import 'package:atelier7/presentation/widgets/settings.widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
     return Scaffold(
        appBar: AppBar(
          elevation: 15,
          backgroundColor: const Color.fromARGB(255, 225, 122, 188),
          title: const Text("Settings and Help"),
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
            ),
        body: const SettingsWidget(),
    );
  }
}
