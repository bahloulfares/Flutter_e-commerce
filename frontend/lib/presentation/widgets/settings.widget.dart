import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:atelier7/presentation/screens/map.screen.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  SettingsWidgetState createState() => SettingsWidgetState();
}

class SettingsWidgetState extends State<SettingsWidget> {
  // Variables pour stocker l'état des Switch
  bool notificationsEnabled = false;
  bool locationEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value; // Mise à jour de l'état
                    });
                    developer.log(
                        'Notifications activées: $notificationsEnabled',
                        name: 'SettingsWidget');
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location services'),
                trailing: Switch(
                  value: locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      locationEnabled = value; // Mise à jour de l'état
                    });
                    developer.log(
                        'Services de localisation activés: $locationEnabled',
                        name: 'SettingsWidget');
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () {
                  // Action à définir pour la section About
                },
              ),
            ],
          ),
        ),
        // Si le service de localisation est activé, afficher la carte
        if (locationEnabled)
          const Expanded(
            child: SizedBox(
              height: 300,
              child: MapScreen(), // Affichage de la carte
            ),
          ),
      ],
    );
  }
}
