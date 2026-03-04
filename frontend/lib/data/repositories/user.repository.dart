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
    await prefs.setString(
        StorageKeys.refreshToken, response['refreshToken'] ?? '');
    await prefs.setString(StorageKeys.userId, user['_id'] ?? '');
    await prefs.setString(StorageKeys.username, user['name'] ?? '');
    await prefs.setString(StorageKeys.email, user['email'] ?? '');
    await prefs.setBool(StorageKeys.isLoggedIn, true);
  }
}
