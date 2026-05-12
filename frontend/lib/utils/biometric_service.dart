import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult {
  success,
  failure,
  cancelled,
  notAvailable,
  permissionDenied,
  lockedOut
}

abstract class IBiometricService {
  Future<bool> isAvailable();
  Future<bool> isFingerprintAvailable();
  Future<bool> isFaceAvailable();
  Future<BiometricResult> authenticate({required String reason});
  Future<String> getBiometricType();
}

class BiometricService implements IBiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final deviceSupported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();

      developer.log(
        '🔍 Biometric: canCheck=$canCheck, deviceSupported=$deviceSupported, biometrics=$biometrics',
        name: 'BiometricService',
      );

      if (!canCheck && !deviceSupported) return false;
      return biometrics.isNotEmpty || deviceSupported;
    } catch (e) {
      developer.log('❌ isAvailable error: $e', name: 'BiometricService');
      try {
        return await _auth.isDeviceSupported();
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<String> getBiometricType() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Empreinte digitale';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Reconnaissance oculaire';
      }
      return 'Biométrie';
    } catch (_) {
      return 'Biométrie';
    }
  }

  @override
  Future<bool> isFingerprintAvailable() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.fingerprint)) return true;
      // Fallback Transsion/Infinix : si l'appareil supporte la biométrie
      // et que la liste est vide, on suppose que l'empreinte est disponible
      final deviceSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return deviceSupported && canCheck && biometrics.isEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isFaceAvailable() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      // Face ID explicitement listé
      return biometrics.contains(BiometricType.face);
      // Note: sur Infinix, face n'est généralement pas listé séparément
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final available = await isAvailable();
      if (!available) {
        developer.log('❌ Biometric not available', name: 'BiometricService');
        return BiometricResult.notAvailable;
      }

      final biometricType = await getBiometricType();
      developer.log('🔐 Authenticating with: $biometricType',
          name: 'BiometricService');

      final authenticated = await _auth.authenticate(
        localizedReason: '$reason ($biometricType)',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      developer.log(
          authenticated ? '✅ Auth success' : '❌ Auth failed',
          name: 'BiometricService');

      return authenticated ? BiometricResult.success : BiometricResult.failure;
    } on PlatformException catch (e) {
      developer.log('❌ PlatformException: code=${e.code} msg=${e.message}',
          name: 'BiometricService');
      return _mapException(e);
    } catch (e) {
      developer.log('❌ Unknown error: $e', name: 'BiometricService');
      return BiometricResult.failure;
    }
  }

  BiometricResult _mapException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
      case 'NotEnrolled':
      case 'PasscodeNotSet':
        return BiometricResult.notAvailable;
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return BiometricResult.lockedOut;
      case 'UserCanceled':
      case 'SystemCanceled':
        return BiometricResult.cancelled;
      case 'PermissionDenied':
        return BiometricResult.permissionDenied;
      default:
        return BiometricResult.failure;
    }
  }
}
