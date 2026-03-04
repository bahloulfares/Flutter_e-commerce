import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Classe utilitaire pour gérer le hashage sécurisé des mots de passe
class PasswordHelper {
  /// Hash un mot de passe en utilisant SHA-256
  /// Ajoute un salt pour plus de sécurité
  static String hashPassword(String password) {
    // Ajout d'un salt pour renforcer la sécurité
    const String salt = 'atelier7_secure_salt_2026';
    final String saltedPassword = salt + password;

    // Hashage avec SHA-256
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Vérifie si un mot de passe correspond au hash stocké
  static bool verifyPassword(String password, String hashedPassword) {
    final String newHash = hashPassword(password);
    return newHash == hashedPassword;
  }

  /// Valide la force d'un mot de passe
  /// Retourne true si le mot de passe est assez fort
  static bool isPasswordStrong(String password) {
    if (password.length < 6) return false;

    // Au moins une lettre et un chiffre
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));

    return hasLetter && hasDigit;
  }

  /// Retourne un message d'erreur si le mot de passe n'est pas valide
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Le mot de passe ne peut pas être vide';
    }
    if (password.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (!isPasswordStrong(password)) {
      return 'Le mot de passe doit contenir des lettres et des chiffres';
    }
    return null;
  }
}
