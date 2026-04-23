import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atelier7/domain/usecases/user.usecase.dart';
import 'package:atelier7/utils/constants.dart';
import 'package:atelier7/utils/biometric_service.dart';
import 'package:atelier7/utils/secure_storage_service.dart';

class AuthController extends GetxController {
  final AuthenticateUserUseCase _userUseCase;
  final IBiometricService _biometricService;
  final ISecureStorageService _secureStorage;

  AuthController({
    required AuthenticateUserUseCase userUseCase,
    IBiometricService? biometricService,
    ISecureStorageService? secureStorage,
  })  : _userUseCase = userUseCase,
        _biometricService = biometricService ?? BiometricService(),
        _secureStorage = secureStorage ?? SecureStorageService();

  var isAuthenticated = false.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userId = ''.obs;
  var userAvatar = ''.obs;
  var userRole = ''.obs;
  var isProfileLoading = false.obs;
  var isBiometricAvailable = false.obs;  // appareil supporte la biométrie
  var isBiometricEnabled = false.obs;    // utilisateur a activé la biométrie dans les paramètres
  var lastBiometricResult = BiometricResult.success.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    checkBiometricAvailability();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    isAuthenticated.value = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
    userName.value = prefs.getString(StorageKeys.username) ?? '';
    userEmail.value = prefs.getString(StorageKeys.email) ?? '';
    userId.value = prefs.getString(StorageKeys.userId) ?? '';
    userAvatar.value = prefs.getString(StorageKeys.avatar) ?? '';
    userRole.value = prefs.getString(StorageKeys.userRole) ?? 'user';
    isBiometricEnabled.value = prefs.getBool('biometric_enabled') ?? false;
  }

  bool get isAdmin => userRole.value == 'admin';

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
    // On garde les credentials biométriques pour permettre la reconnexion par biométrie
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    await prefs.clear();
    // Restaurer le flag biométrie si elle était activée
    if (biometricEnabled) {
      await prefs.setBool('biometric_enabled', true);
    }
    isAuthenticated.value = false;
    userName.value = '';
    userEmail.value = '';
    userId.value = '';
    userAvatar.value = '';
    userRole.value = 'user';
    isBiometricEnabled.value = biometricEnabled;
  }

  Future<void> checkBiometricAvailability() async {
    isBiometricAvailable.value = await _biometricService.isAvailable();
  }

  /// Active la biométrie : vérifie les credentials auprès du backend SANS refaire le login complet
  Future<bool> enableBiometric(String email, String password) async {
    final deviceOk = await _biometricService.isAvailable();
    if (!deviceOk) return false;

    // Vérifier les credentials sans toucher à l'état auth courant
    final valid = await _userUseCase.verifyCredentials(email, password);
    if (!valid) return false;

    await _secureStorage.saveCredentials(email, password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', true);
    isBiometricEnabled.value = true;
    return true;
  }

  /// Désactive la biométrie
  Future<void> disableBiometric() async {
    await _secureStorage.deleteCredentials();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', false);
    isBiometricEnabled.value = false;
  }

  Future<bool> loginWithBiometrics() async {
    final result = await _biometricService.authenticate(
      reason: 'Connectez-vous avec votre empreinte ou Face ID',
    );
    lastBiometricResult.value = result;

    if (result == BiometricResult.cancelled) return false;
    if (result != BiometricResult.success) return false;

    final creds = await _secureStorage.getCredentials();
    if (creds == null) {
      isBiometricAvailable.value = false;
      return false;
    }
    return login(creds.email, creds.password);
  }

  Future<void> saveBiometricCredentials(String email, String password) async {
    await _secureStorage.saveCredentials(email, password);
    isBiometricAvailable.value = true;
  }

  Future<void> fetchProfile() async {
    try {
      isProfileLoading.value = true;
      await _userUseCase.getProfile();
      await _loadUserData();
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String avatar = '',
  }) async {
    try {
      isProfileLoading.value = true;
      await _userUseCase.updateProfile(
        name: name,
        email: email,
        avatar: avatar,
      );
      await _loadUserData();
      return true;
    } catch (_) {
      return false;
    } finally {
      isProfileLoading.value = false;
    }
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
