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
  }

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
  }
}
