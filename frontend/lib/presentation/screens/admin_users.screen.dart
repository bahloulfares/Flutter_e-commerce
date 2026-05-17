import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text('edit_role_of'.tr.replaceAll('{name}', '${user['name']}')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Color.fromARGB(255, 175, 30, 124),
              ),
              title: Text('admin_role'.tr),
              selected: currentRole == 'admin',
              selectedTileColor: const Color.fromARGB(
                255,
                175,
                30,
                124,
              ).withValues(alpha: 0.1),
              onTap: () async {
                Navigator.pop(ctx);
                if (currentRole != 'admin') {
                  await _changeRole(user, 'admin');
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.person,
                color: Color.fromARGB(255, 30, 175, 124),
              ),
              title: Text('user_role'.tr),
              selected: currentRole == 'user',
              selectedTileColor: const Color.fromARGB(
                255,
                30,
                175,
                124,
              ).withValues(alpha: 0.1),
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
            child: Text('annuler'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(Map<String, dynamic> user, String role) async {
    final ok = await _authController.updateUserRole(user['id'] as int, role);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'role_changed_to'.tr
                      .replaceAll('{name}', '${user['name']}')
                      .replaceAll(
                        '{role}',
                        role == 'admin' ? 'admin_role'.tr : 'user_role'.tr,
                      )
                : 'role_change_error'.tr,
          ),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> user) {
    // Prevent deleting yourself
    if (user['email'] == _authController.userEmail.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cannot_delete_self'.tr),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_user_question'.tr),
        content: Text(
          'delete_user_content'.tr
              .replaceAll('{name}', '${user['name']}')
              .replaceAll('{email}', '${user['email']}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('annuler'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authController.deleteUser(user['id'] as int);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'manage_users'.tr,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'no_users'.tr,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
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

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.outline
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    Text(
                      user['name']?.toString() ?? 'unknown'.tr,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'you'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['email']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? const Color.fromARGB(
                                255,
                                175,
                                30,
                                124,
                              ).withValues(alpha: 0.15)
                            : const Color.fromARGB(
                                255,
                                30,
                                175,
                                124,
                              ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAdmin ? 'admin_role'.tr : 'user_role'.tr,
                        style: GoogleFonts.poppins(
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
                                ? 'demote_to_user'.tr
                                : 'promote_to_admin'.tr,
                            onPressed: () => _showRoleDialog(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'delete'.tr,
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
