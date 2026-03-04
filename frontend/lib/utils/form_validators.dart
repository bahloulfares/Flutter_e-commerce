/// Classe utilitaire pour valider les entrées des formulaires
class FormValidators {
  /// Valide un nom d'utilisateur
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }
    if (value.length < 3) {
      return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
    }
    if (value.length > 20) {
      return 'Le nom d\'utilisateur ne peut pas dépasser 20 caractères';
    }
    // Autoriser seulement lettres, chiffres et underscore
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres et _';
    }
    return null;
  }

  /// Valide un mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (value.length > 50) {
      return 'Le mot de passe ne peut pas dépasser 50 caractères';
    }
    // Au moins une lettre et un chiffre
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une lettre';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    return null;
  }

  /// Valide un email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  /// Valide un nom de catégorie
  static String? validateCategoryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom de la catégorie est requis';
    }
    if (value.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    if (value.length > 50) {
      return 'Le nom ne peut pas dépasser 50 caractères';
    }
    return null;
  }

  /// Valide un prix
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le prix est requis';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Veuillez entrer un nombre valide';
    }
    if (price < 0) {
      return 'Le prix ne peut pas être négatif';
    }
    if (price > 999999) {
      return 'Le prix est trop élevé';
    }
    return null;
  }

  /// Valide une quantité
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'La quantité est requise';
    }
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Veuillez entrer un nombre entier';
    }
    if (quantity < 0) {
      return 'La quantité ne peut pas être négative';
    }
    if (quantity > 100000) {
      return 'La quantité est trop élevée';
    }
    return null;
  }

  /// Valide un champ texte générique (non vide)
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valide la longueur d'un champ texte
  static String? validateLength(
    String? value,
    String fieldName, {
    int? min,
    int? max,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    if (min != null && value.length < min) {
      return '$fieldName doit contenir au moins $min caractères';
    }
    if (max != null && value.length > max) {
      return '$fieldName ne peut pas dépasser $max caractères';
    }
    return null;
  }

  /// Valide une URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL optionnelle
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Veuillez entrer une URL valide';
    }
    return null;
  }

  /// Valide la confirmation d'un mot de passe
  static String? validatePasswordConfirmation(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    if (value != originalPassword) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }
}
