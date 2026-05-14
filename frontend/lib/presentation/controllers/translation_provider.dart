import 'dart:async';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:atelier7/utils/mlkit_translation_manager.dart';

/// 🎯 GetX Controller pour gérer les traductions réactives
/// - Traduit tous les textes automatiquement quand la langue change
/// - Fournit une RxMap pour que les widgets accèdent aux traductions
/// - Gère le cache et le status de traduction
class TranslationProvider extends GetxController {
  // Instance du manager ML Kit
  final MLKitTranslationManager _mlkitManager = MLKitTranslationManager();

  // 🔴 Variables réactives
  final currentLanguage = 'fr'.obs; // Langue actuelle de l'UI
  final sourceLanguage = 'fr'.obs; // Langue source du texte original
  final isTranslating = false.obs; // Flag: traduction en cours?
  final translationProgress = 0.0.obs; // 0.0 to 1.0

  // 🔴 Map réactive: clé -> texte traduit
  // Exemple: "categories" -> "Catégories" (si langue = fr)
  final translations = <String, String>{}.obs;

  // Ensemble de textes à traduire
  final Set<String> _textSet = {
    // ===== MENU PRINCIPAL (Sidebar) =====
    'accueil', // Home
    'categories', // Categories
    'Sous-catégories', // SubCategories
    'Articles (admin)', // Admin Articles
    'commandes', // Orders
    'utilisateurs', // Users
    'produits', // Products
    'panier', // Cart
    'profil', // Profile
    'parametres', // Settings
    'inscription', // Register
    'connexion', // Login
    'deconnexion', // Logout
    'ADMIN', // Admin badge
    'Utilisateur', // User label
    'About app', // About section

    // ===== APPBAR =====
    'boutique', // Shop
    'Panier', // Cart (uppercase variant)
    'shopping_cart', // Shopping cart

    // ===== SHOPPING / CART =====
    'Ajouter au panier', // Add to cart
    'Supprimer', // Remove
    'Total', // Total
    'Panier vide', // Empty cart
    'Shop now', // Shop now
    'Passer la commande', // Checkout
    'Product removed from cart',
    'Product not found in the cart',

    // ===== SETTINGS =====
    'Theme', // Theme
    'Language', // Language
    'Notifications', // Notifications
    'Biometric', // Biometric
    'Face ID', // Face ID
    'Activer Face ID', // Enable Face ID
    'Activer l\'empreinte', // Enable fingerprint
    'Entrez vos identifiants pour confirmer :', // Enter credentials to confirm
    'Face ID activé(e) avec succès', // Face ID enabled successfully
    'Identifiants invalides ou biométrie non disponible', // Invalid credentials or biometry unavailable

    // ===== PRODUITS / ARTICLES =====
    'Scanner un produit', // Scan a product
    'Scanner avec la caméra', // Scan with camera
    'Scanner depuis la galerie', // Scan from gallery
    'Assistant', // Assistant
    'Référence détectée', // Reference detected
    'Référence déjà existante', // Reference already exists
    'Erreur scan galerie', // Gallery scan error
    'Image uploadée avec succès', // Image uploaded successfully
    'Erreur upload image', // Image upload error    'bienvenue',              // Welcome
    'rechercher', // Search
    'tout', // All
    'client', // Client
    'aucun_produit', // No products
    'retirer', // Remove/Withdraw
    'ajouter', // Add
    // ===== COMMANDES / ORDERS =====
    'Commande #', // Order #
    'Commande confirmée !', // Order confirmed!
    'Merci pour votre commande', // Thank you for your order
    'Changer le statut :', // Change status:
    'Not processed', // Not processed
    'Processing', // Processing
    'Shipped', // Shipped
    'Delivered', // Delivered
    'Cancelled', // Cancelled
    'Statut mis à jour', // Status updated
    'Erreur mise à jour', // Update error
    'Supprimer la commande ?', // Delete order?
    // ===== GESTION ADMIN =====
    'Aucune sous-catégorie', // No subcategories
    'Supprimer la sous-catégorie ?', // Delete subcategory?
    'Supprimé avec succès', // Deleted successfully
    'Erreur suppression', // Deletion error
    'Modifier le rôle de', // Change role of
    'Annuler', // Cancel
    'Vous ne pouvez pas supprimer votre propre compte', // Cannot delete own account
    'Supprimer l\'utilisateur ?', // Delete user?
    'rôle changé à', // role changed to

    // ===== FORMULAIRES =====
    'Category name', // Category name
    'Créer un compte', // Create account
    'Inscrivez-vous pour accéder à toutes les fonctionnalités', // Register to access features
    'Nom', // Name
    'Email', // Email
    'Password', // Password
    'Retape Password', // Confirm Password
    'Compte créé avec succès', // Account created successfully
    'Placez votre visage dans le cadre et appuyez sur le bouton', // Place face in frame
    'Regardez la caméra pour vous connecter', // Look at camera to login
    'Visage reconnu', // Face recognized
    'Trop de tentatives', // Too many attempts
    'Permission biométrique refusée', // Biometric permission denied
    'Biométrie non disponible', // Biometry not available
    'Authentification échouée', // Authentication failed

    // ===== MESSAGES COMMUNS =====
    'Placez le code-barres dans le cadre', // Place barcode in frame
    'Détails de la commande', // Order details
    'Mot de passe', // Password
    'TND', // Currency (Tunisian Dinar)
    'loading', // Loading
    'error', // Error
    'success', // Success
    'ok', // OK
    'cancel', // Cancel
    'done', // Done
    'Ajouter', // Add
    'Modifier', // Edit
    'Accueil', // Home (alternate form)
    'PICK FROM GALLERY', // Pick from gallery
    'PICK FROM CAMERA', // Pick from camera
    'Image non disponible', // Image not available
  };

  @override
  void onInit() {
    super.onInit();
    _mlkitManager.setSourceLanguage(sourceLanguage.value);
    _seedNativeTranslations();
    developer.log(
      '🚀 TranslationProvider initialisé. Langue source: ${sourceLanguage.value}',
      name: 'TranslationProvider',
    );
  }

  /// Charge les textes natifs de base pour la langue source.
  /// Comme l'app démarre en français, la version native est une identité.
  void _seedNativeTranslations() {
    translations.clear();
    for (final key in _textSet) {
      translations[key] = key;
    }
  }

  /// ✅ SETTER: Changer la langue et traduire
  /// [newLanguage] - Code langue (en, fr, ar)
  Future<void> setLanguage(String newLanguage) async {
    if (newLanguage == currentLanguage.value && translations.isNotEmpty) {
      developer.log(
        '⏭️ Langue déjà définie à $newLanguage',
        name: 'TranslationProvider',
      );
      return;
    }

    developer.log(
      '🔄 Changement de langue: ${currentLanguage.value} → $newLanguage',
      name: 'TranslationProvider',
    );

    try {
      isTranslating.value = true;

      // Étape 1: Définir la langue actuelle
      currentLanguage.value = newLanguage;

      // Si on revient à la langue source, réinitialiser l'affichage natif.
      if (newLanguage == sourceLanguage.value) {
        _seedNativeTranslations();
        developer.log(
          '✅ Langue source restaurée, textes natifs réinitialisés',
          name: 'TranslationProvider',
        );
        return;
      }

      // Étape 2: Si langue source change aussi, vider le cache
      if (sourceLanguage.value != newLanguage) {
        _mlkitManager.changeSourceLanguage(sourceLanguage.value);
      }

      // Étape 3: Traduire TOUS les textes en parallèle
      final textList = _textSet.toList();
      developer.log(
        '📝 Traduction de ${textList.length} textes vers $newLanguage...',
        name: 'TranslationProvider',
      );

      final translatedTexts =
          await _mlkitManager.translateMultiple(textList, newLanguage);

      // Étape 4: Mettre à jour la map réactive
      translations.clear(); // Vider l'ancienne map
      translatedTexts.forEach((key, value) {
        translations[key] = value;
      });

      developer.log(
        '✅ Tous les textes traduits! Map mise à jour avec ${translations.length} entrées.',
        name: 'TranslationProvider',
      );
    } catch (e) {
      developer.log(
        '❌ Erreur lors du changement de langue: $e',
        name: 'TranslationProvider',
      );
      isTranslating.value = false;
      rethrow;
    } finally {
      isTranslating.value = false;
    }
  }

  /// ✅ GETTER: Obtenir un texte traduit
  /// [key] - Clé du texte (ex: "categories")
  /// Retourne: Le texte traduit (ou la clé si pas trouvé)
  String getTranslation(String key) {
    if (translations.containsKey(key)) {
      return translations[key]!;
    }
    developer.log(
      '⚠️ Clé "$key" non trouvée dans les traductions',
      name: 'TranslationProvider',
    );
    return key; // Retourner la clé elle-même comme fallback
  }

  /// ✅ Ajouter un nouveau texte à traduire (dynamique)
  /// Utile pour les descriptions ou textes personnalisés
  Future<String> translateText(String text) async {
    final translated =
        await _mlkitManager.translate(text, currentLanguage.value);
    return translated;
  }

  /// ✅ Ajouter plusieurs nouveaux textes et les traduire
  Future<Map<String, String>> translateTexts(List<String> texts) async {
    return await _mlkitManager.translateMultiple(texts, currentLanguage.value);
  }

  /// ✅ Ajouter une clé à l'ensemble à traduire
  /// À appeler pour toute nouvelle clé découverte dynamiquement
  void registerKey(String key) {
    if (!_textSet.contains(key)) {
      _textSet.add(key);
      developer.log(
        '📌 Nouvelle clé enregistrée: $key',
        name: 'TranslationProvider',
      );
    }
  }

  /// ✅ Ajouter plusieurs clés
  void registerKeys(List<String> keys) {
    for (final key in keys) {
      registerKey(key);
    }
  }

  /// ✅ Initialiser avec des traductions pré-chargées
  /// Utile si tu as des traductions JSON ou un autre source
  void preloadTranslations(Map<String, String> texts) {
    translations.addAll(texts);
    developer.log(
      '💾 ${texts.length} traductions pré-chargées',
      name: 'TranslationProvider',
    );
  }

  /// ✅ Forcer une retranslation complète
  Future<void> retranslate() async {
    await setLanguage(currentLanguage.value);
  }

  @override
  void onClose() {
    _mlkitManager.dispose();
    super.onClose();
  }
}
