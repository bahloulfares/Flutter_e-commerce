import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'package:atelier7/presentation/controllers/user.controller.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Drawer(
      child: ListView(
        children: [
          GetBuilder<AuthController>(
            builder: (_) => UserAccountsDrawerHeader(
              accountName: Text(authController.userName.value.isNotEmpty
                  ? authController.userName.value
                  : "Utilisateur"),
              accountEmail: Text(authController.userEmail.value.isNotEmpty
                  ? authController.userEmail.value
                  : "email@example.com"),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 30, 175, 124),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://cdn-icons-png.flaticon.com/512/6858/6858504.png',
                ),
              ),
            ),
          ),
          ...choices.map((Choice choice) {
            return ListTile(
              leading: Icon(choice.icon, color: Colors.blueGrey),
              textColor: Colors.blueGrey,
              title: Text(choice.title),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                developer.log('Drawer choice: ${choice.title}',
                    name: 'MyDrawer');
                Navigator.pop(context);
                Navigator.pushNamed(context, choice.route);
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            textColor: Colors.redAccent,
            title: const Text("Déconnexion"),
            onTap: () async {
              final navigator = Navigator.of(context);
              await authController.logout();
              navigator.pop();
              navigator.pushNamedAndRemoveUntil('/Settings', (route) => false);
            },
          ),
          const AboutListTile(
            icon: Icon(
              Icons.info,
              color: Colors.redAccent,
            ),
            applicationIcon: Icon(
              Icons.local_play,
            ),
            applicationName: 'isetsfax',
            applicationVersion: '13.11.25',
            applicationLegalese: '© 2024 Company',
            child: Text('About app'),
          ),
        ],
      ),
    );
  }
}

class Choice {
  const Choice({required this.title, required this.icon, required this.route});
  final String title;
  final IconData icon;
  final String route;
}

const List<Choice> choices = <Choice>[
  Choice(title: 'Accueil', icon: Icons.home, route: '/'),
  Choice(title: 'Catégories', icon: Icons.category, route: '/Categories'),
  Choice(title: 'Produits', icon: Icons.shopping_bag, route: '/Products'),
  Choice(title: 'Panier', icon: Icons.shopping_cart, route: '/shopping'),
  Choice(title: 'Inscription', icon: Icons.person_add, route: '/Subscribe'),
  Choice(title: 'Paramètres', icon: Icons.settings, route: '/settingsDetails'),
  Choice(title: 'Connexion', icon: Icons.login, route: '/Settings'),
];
