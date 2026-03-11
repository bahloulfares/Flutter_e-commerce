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
          Obx(
            () => UserAccountsDrawerHeader(
              accountName: Text(authController.userName.value.isNotEmpty
                  ? authController.userName.value
                  : "Utilisateur"),
              accountEmail: Text(authController.userEmail.value.isNotEmpty
                  ? authController.userEmail.value
                  : "email@example.com"),
              decoration: BoxDecoration(
                color: authController.userRole.value == 'admin'
                    ? const Color.fromARGB(255, 175, 30, 124) // Rose pour admin
                    : const Color.fromARGB(255, 30, 175, 124), // Vert pour user
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: authController.userAvatar.value.isNotEmpty
                    ? NetworkImage(authController.userAvatar.value)
                    : null,
                child: authController.userAvatar.value.isEmpty
                    ? Icon(
                        authController.userRole.value == 'admin'
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        size: 40,
                        color: authController.userRole.value == 'admin'
                            ? const Color.fromARGB(255, 175, 30, 124)
                            : const Color.fromARGB(255, 30, 175, 124),
                      )
                    : null,
              ),
              otherAccountsPictures: [
                if (authController.userRole.value == 'admin')
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Menu items - filtrés selon le rôle et l'authentification
          ...choices.where((choice) {
            final isAuthenticated = authController.isAuthenticated.value;
            final isAdmin = authController.isAdmin;

            // Routes admin : seulement pour admins
            if (choice.adminOnly) {
              return isAdmin;
            }

            // Routes nécessitant une authentification : seulement si connecté
            if (choice.requiresAuth) {
              return isAuthenticated;
            }

            // Connexion et Inscription : afficher seulement si pas connecté
            if (choice.route == '/Settings' || choice.route == '/Subscribe') {
              return !isAuthenticated;
            }

            // Routes publiques (Accueil, Produits) : afficher pour tous
            return isAuthenticated ||
                choice.route == '/' ||
                choice.route == '/Products';
          }).map((Choice choice) {
            return ListTile(
              leading: Icon(choice.icon, color: Colors.blueGrey),
              textColor: Colors.blueGrey,
              title: Row(
                children: [
                  Text(choice.title),
                  if (choice.adminOnly)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    ),
                ],
              ),
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
          // Bouton déconnexion : visible seulement si connecté
          Obx(() {
            if (!authController.isAuthenticated.value) {
              return const SizedBox.shrink();
            }
            return ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              textColor: Colors.redAccent,
              title: const Text("Déconnexion"),
              onTap: () async {
                final navigator = Navigator.of(context);
                await authController.logout();
                navigator.pop();
                navigator.pushNamedAndRemoveUntil(
                    '/Settings', (route) => false);
              },
            );
          }),
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
  const Choice({
    required this.title,
    required this.icon,
    required this.route,
    this.adminOnly = false,
    this.requiresAuth = false,
    this.userOnly = false,
  });
  final String title;
  final IconData icon;
  final String route;
  final bool adminOnly;
  final bool requiresAuth;
  final bool userOnly;
}

const List<Choice> choices = <Choice>[
  Choice(title: 'Accueil', icon: Icons.home, route: '/'),
  Choice(
    title: 'Catégories',
    icon: Icons.category,
    route: '/Categories',
    adminOnly: true,
  ),
  Choice(
    title: 'Sous-catégories',
    icon: Icons.subdirectory_arrow_right,
    route: '/admin/scategories',
    adminOnly: true,
  ),
  Choice(
    title: 'Articles (admin)',
    icon: Icons.inventory_2,
    route: '/admin/articles',
    adminOnly: true,
  ),
  Choice(
    title: 'Commandes',
    icon: Icons.receipt_long,
    route: '/admin/orders',
    adminOnly: true,
  ),
  Choice(
    title: 'Utilisateurs',
    icon: Icons.people,
    route: '/admin/users',
    adminOnly: true,
  ),
  Choice(title: 'Produits', icon: Icons.shopping_bag, route: '/Products'),
  Choice(
    title: 'Panier',
    icon: Icons.shopping_cart,
    route: '/cartView',
    requiresAuth: true,
  ),
  Choice(
    title: 'Profil',
    icon: Icons.account_circle,
    route: '/profile',
    requiresAuth: true,
  ),
  Choice(
    title: 'Paramètres',
    icon: Icons.settings,
    route: '/settingsDetails',
    requiresAuth: true,
  ),
  Choice(
    title: 'Inscription',
    icon: Icons.person_add,
    route: '/Subscribe',
  ),
  Choice(
    title: 'Connexion',
    icon: Icons.login,
    route: '/Settings',
  ),
];
