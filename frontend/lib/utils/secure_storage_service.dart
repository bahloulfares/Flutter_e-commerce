import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ISecureStorageService {
  Future<void> saveCredentials(String email, String password);
  Future<({String email, String password})?> getCredentials();
  Future<void> deleteCredentials();
  Future<bool> hasCredentials();

  Future<void> saveFaceIdCredentials(String email, String password);
  Future<({String email, String password})?> getFaceIdCredentials();
  Future<void> deleteFaceIdCredentials();
  Future<bool> hasFaceIdCredentials();
}

class SecureStorageService implements ISecureStorageService {
  static const _kEmail = 'biometric_email';
  static const _kPassword = 'biometric_password';
  static const _kFaceIdEmail = 'face_id_mlkit_email';
  static const _kFaceIdPassword = 'face_id_mlkit_password';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPassword, value: password);
  }

  @override
  Future<({String email, String password})?> getCredentials() async {
    try {
      final email = await _storage.read(key: _kEmail);
      final password = await _storage.read(key: _kPassword);

      // Credentials corrompus : un seul présent ou vides
      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        await deleteCredentials();
        return null;
      }
      return (email: email, password: password);
    } catch (_) {
      await deleteCredentials();
      return null;
    }
  }

  @override
  Future<void> deleteCredentials() async {
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPassword);
  }

  @override
  Future<bool> hasCredentials() async {
    final creds = await getCredentials();
    return creds != null;
  }

  @override
  Future<void> saveFaceIdCredentials(String email, String password) async {
    await _storage.write(key: _kFaceIdEmail, value: email);
    await _storage.write(key: _kFaceIdPassword, value: password);
  }

  @override
  Future<({String email, String password})?> getFaceIdCredentials() async {
    try {
      final email = await _storage.read(key: _kFaceIdEmail);
      final password = await _storage.read(key: _kFaceIdPassword);

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        await deleteFaceIdCredentials();
        return null;
      }
      return (email: email, password: password);
    } catch (_) {
      await deleteFaceIdCredentials();
      return null;
    }
  }

  @override
  Future<void> deleteFaceIdCredentials() async {
    await _storage.delete(key: _kFaceIdEmail);
    await _storage.delete(key: _kFaceIdPassword);
  }

  @override
  Future<bool> hasFaceIdCredentials() async {
    final creds = await getFaceIdCredentials();
    return creds != null;
  }
}
