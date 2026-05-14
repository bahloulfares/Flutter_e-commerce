import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthPreferences {
  static const String _emailKey = 'user_email';
  static const String _tokenKey = 'auth_token';
  static const String _rememberMeKey = 'remember_me';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';

  static final AuthPreferences _instance = AuthPreferences._internal();
  late SharedPreferences _prefs;
  late FlutterSecureStorage _secureStorage;

  factory AuthPreferences() {
    return _instance;
  }

  AuthPreferences._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();
  }

  // ===== TOKEN =====
  Future<void> setToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // ===== EMAIL =====
  Future<void> setEmail(String email) async {
    await _prefs.setString(_emailKey, email);
  }

  Future<String?> getEmail() async {
    return _prefs.getString(_emailKey);
  }

  Future<void> clearEmail() async {
    await _prefs.remove(_emailKey);
  }

  // ===== REMEMBER ME =====
  Future<void> setRememberMe(bool value) async {
    await _prefs.setBool(_rememberMeKey, value);
  }

  bool isRememberMe() {
    return _prefs.getBool(_rememberMeKey) ?? false;
  }

  // ===== USER INFO =====
  Future<void> setUserId(String id) async {
    await _prefs.setString(_userIdKey, id);
  }

  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
  }

  String? getUserName() {
    return _prefs.getString(_userNameKey);
  }

  Future<void> setUserRole(String role) async {
    await _prefs.setString(_userRoleKey, role);
  }

  String? getUserRole() {
    return _prefs.getString(_userRoleKey);
  }

  // ===== LOGOUT =====
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _tokenKey);
    await _prefs.clear();
  }

  // ===== CHECK IF LOGGED IN =====
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
