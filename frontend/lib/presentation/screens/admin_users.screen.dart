import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authController.fetchAllUsers();
    });
  }

  void _showRoleDialog(Map<String, dynamic> user) {
    final currentRole = user['role'] as String? ?? 'user';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le rôle de ${user['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings,
                  color: Color.fromARGB(255, 175, 30, 124)),
              title: const Text('Admin'),
              selected: currentRole == 'admin',
              selectedTileColor: const Color.fromARGB(255, 175, 30, 124)
                  .withValues(alpha: 0.1),
              onTap: () async {
                Navigator.pop(ctx);
                if (currentRole != 'admin') {
                  await _changeRole(user, 'admin');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person,
                  color: Color.fromARGB(255, 30, 175, 124)),
              title: const Text('Utilisateur'),
              selected: currentRole == 'user',
              selectedTileColor: const Color.fromARGB(255, 30, 175, 124)
                  .withValues(alpha: 0.1),
              onTap: () async {
                Navigator.pop(ctx);
                if (currentRole != 'user') {
                  await _changeRole(user, 'user');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
        ],
      ),
    );
  }

  Future<void> _changeRole(Map<String, dynamic> user, String role) async {
    final ok = await _authController.updateUserRole(user['id'] as int, role);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '${user['name']} : rôle changé à "$role"'
            : 'Erreur changement de rôle'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  void _confirmDelete(Map<String, dynamic> user) {
    // Prevent deleting yourself
    if (user['email'] == _authController.userEmail.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vous ne pouvez pas supprimer votre propre compte.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur ?'),
        content: Text('Supprimer "${user['name']}" (${user['email']}) ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authController.deleteUser(user['id'] as int);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: const Color.fromARGB(255, 175, 30, 124),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _authController.fetchAllUsers,
          ),
        ],
      ),
      body: Obx(() {
        if (_authController.isUsersLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_authController.usersList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Aucun utilisateur', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final users = _authController.usersList;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final user = users[i];
            final role = user['role'] as String? ?? 'user';
            final isAdmin = role == 'admin';
            final isSelf = user['email'] == _authController.userEmail.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin
                      ? const Color.fromARGB(255, 175, 30, 124)
                      : const Color.fromARGB(255, 30, 175, 124),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Row(
                  children: [
                    Text(user['name']?.toString() ?? 'Inconnu',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Vous',
                            style:
                                TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['email']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12)),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? const Color.fromARGB(255, 175, 30, 124)
                                .withValues(alpha: 0.15)
                            : const Color.fromARGB(255, 30, 175, 124)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAdmin ? 'Admin' : 'Utilisateur',
                        style: TextStyle(
                          fontSize: 11,
                          color: isAdmin
                              ? const Color.fromARGB(255, 175, 30, 124)
                              : const Color.fromARGB(255, 30, 175, 124),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: isSelf
                    ? null
                    : Wrap(
                        children: [
                          IconButton(
                            icon: Icon(
                              isAdmin
                                  ? Icons.person
                                  : Icons.admin_panel_settings,
                              color: Colors.blue,
                            ),
                            tooltip: isAdmin
                                ? 'Rétrograder en utilisateur'
                                : 'Promouvoir en admin',
                            onPressed: () => _showRoleDialog(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Supprimer',
                            onPressed: () => _confirmDelete(user),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      }),
    );
  }
}
