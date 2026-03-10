import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atelier7/domain/usecases/user.usecase.dart';
import 'package:atelier7/utils/constants.dart';

class AuthController extends GetxController {
  final AuthenticateUserUseCase _userUseCase;

  AuthController({required AuthenticateUserUseCase userUseCase})
      : _userUseCase = userUseCase;

  var isAuthenticated = false.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userId = ''.obs;
  var userRole = ''.obs; // 'user' ou 'admin'

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    isAuthenticated.value = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
    userName.value = prefs.getString(StorageKeys.username) ?? '';
    userEmail.value = prefs.getString(StorageKeys.email) ?? '';
    userId.value = prefs.getString(StorageKeys.userId) ?? '';
    userRole.value = prefs.getString(StorageKeys.userRole) ?? 'user';
  }

  // Vérifier si l'utilisateur est admin
  bool get isAdmin => userRole.value == 'admin';

  // Vérifier si l'utilisateur est un client normal
  bool get isUser => userRole.value == 'user';

  Future<bool> login(String email, String password) async {
    final res = await _userUseCase.call(email, password);
    if (res) {
      await _loadUserData();
    }
    return res;
  }

  Future<bool> register(String name, String email, String password) async {
    return _userUseCase.register(name, email, password);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isAuthenticated.value = false;
    userName.value = '';
    userEmail.value = '';
    userId.value = '';
    userRole.value = 'user';
  }

  // Admin: users management
  var usersList = <Map<String, dynamic>>[].obs;
  var isUsersLoading = false.obs;

  Future<void> fetchAllUsers() async {
    try {
      isUsersLoading.value = true;
      usersList.value = await _userUseCase.getAllUsers();
    } catch (e) {
      usersList.value = [];
    } finally {
      isUsersLoading.value = false;
    }
  }

  Future<bool> updateUserRole(int id, String role) async {
    try {
      await _userUseCase.updateUserRole(id, role);
      final index = usersList.indexWhere((u) => u['id'] == id);
      if (index != -1) {
        usersList[index] = Map<String, dynamic>.from(usersList[index])
          ..['role'] = role;
        usersList.refresh();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      await _userUseCase.deleteUser(id);
      usersList.removeWhere((u) => u['id'] == id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
