import 'dart:developer' as developer;
import 'package:atelier7/data/datasource/services/user.service.dart';
import 'package:atelier7/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  final UserService userService;

  UserRepository({required this.userService});

  Future<bool> authenticate(String email, String password) async {
    final response = await userService.login(email, password);

    if (response['success'] == true) {
      await _persistAuth(response);
      return true;
    }
    return false;
  }

  Future<bool> registerUser(String name, String email, String password) async {
    final response = await userService.register(name, email, password);
    developer.log('User registered: $response', name: 'UserRepository');
    return response['success'] == true;
  }

  Future<void> _persistAuth(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    final user = (response['user'] ?? {}) as Map<String, dynamic>;

    await prefs.setString(StorageKeys.accessToken, response['token'] ?? '');
    await prefs.setString(StorageKeys.token, response['token'] ?? ''); // Alias
    await prefs.setString(
        StorageKeys.refreshToken, response['refreshToken'] ?? '');
    await prefs.setString(
        StorageKeys.userId, (user['id'] ?? user['_id'] ?? '').toString());
    await prefs.setString(StorageKeys.username, user['name'] ?? '');
    await prefs.setString(StorageKeys.email, user['email'] ?? '');
    await prefs.setString(
        StorageKeys.userRole, user['role'] ?? 'user'); // Sauvegarder le rôle
    await prefs.setBool(StorageKeys.isLoggedIn, true);

    developer.log(
        '✅ User authenticated: ${user['name']} (${user['role'] ?? 'user'})',
        name: 'UserRepository');
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await userService.getAllUsers();
  }

  Future<Map<String, dynamic>> updateUserRole(int id, String role) async {
    return await userService.updateUserRole(id, role);
  }

  Future<void> deleteUser(int id) async {
    await userService.deleteUser(id);
  }
}
