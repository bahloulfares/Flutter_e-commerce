import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { success, failure, cancelled, notAvailable }

abstract class IBiometricService {
  Future<bool> isAvailable();
  Future<BiometricResult> authenticate({required String reason});
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
        '🔍 Biometric check: canCheck=$canCheck, deviceSupported=$deviceSupported, biometrics=$biometrics',
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
  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // permet PIN comme fallback si biométrie verrouillée
          stickyAuth: true,
        ),
      );
      return authenticated ? BiometricResult.success : BiometricResult.failure;
    } on PlatformException catch (e) {
      developer.log('❌ authenticate error: code=${e.code} msg=${e.message}',
          name: 'BiometricService');
      return _mapException(e);
    } catch (e) {
      developer.log('❌ authenticate unknown error: $e', name: 'BiometricService');
      return BiometricResult.failure;
    }
  }

  BiometricResult _mapException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
      case 'NotEnrolled':
        return BiometricResult.notAvailable;
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return BiometricResult.failure;
      case 'UserCanceled':
      case 'SystemCanceled':
        return BiometricResult.cancelled;
      default:
        return BiometricResult.failure;
    }
  }
}
