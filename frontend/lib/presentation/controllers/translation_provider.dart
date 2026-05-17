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
    'accueil',
    'categories',
    'Sous-catégories',
    'Articles (admin)',
    'commandes',
    'utilisateurs',
    'produits',
    'panier',
    'profil',
    'parametres',
    'inscription',
    'connexion',
    'deconnexion',
    'ADMIN',
    'Utilisateur',
    'About app',

    // ===== APPBAR / NAV =====
    'boutique',
    'Assistant',
    'shopping_cart',

    // ===== SHOPPING / CART =====
    'Ajouter au panier',
    'Supprimer',
    'Total',
    'Panier vide',
    'Shop now',
    'Passer la commande',
    'Product removed from cart',
    'Product not found in the cart',

    // Currency / misc
    'TND',
    'Scanner un produit',
    'bienvenue',
    'client',

    // ===== SETTINGS =====
    'Theme',
    'Language',
    'Notifications',
    'Biometric',
    'Face ID',
    'Activer Face ID',
    'Activer l\'empreinte',
    'Entrez vos identifiants pour confirmer :',
    'Face ID activé(e) avec succès',
    'Identifiants invalides ou biométrie non disponible',

    // ===== PRODUITS / ARTICLES =====
    'Scanner avec la caméra',
    'Scanner depuis la galerie',
    'Référence détectée',
    'Référence déjà existante',
    'Erreur scan galerie',
    'Image uploadée avec succès',
    'Erreur upload image',
    'rechercher',
    'tout',
    'aucun_produit',
    'retirer',
    'ajouter',

    // ===== COMMANDES / ORDERS =====
    'Commande #',
    'Commande confirmée !',
    'Merci pour votre commande',
    'Changer le statut :',
    'Not processed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
    'Statut mis à jour',
    'Erreur mise à jour',
    'Supprimer la commande ?',

    // ===== GESTION ADMIN =====
    'Aucune sous-catégorie',
    'Supprimer la sous-catégorie ?',
    'Supprimé avec succès',
    'Erreur suppression',
    'Modifier le rôle de',
    'Annuler',
    'Vous ne pouvez pas supprimer votre propre compte',
    'Supprimer l\'utilisateur ?',
    'rôle changé à',

    // ===== FORMULAIRES =====
    'Category name',
    'Créer un compte',
    'Inscrivez-vous pour accéder à toutes les fonctionnalités',
    'Nom',
    'Email',
    'Password',
    'Retape Password',
    'Compte créé avec succès',
    'Placez votre visage dans le cadre et appuyez sur le bouton',
    'Regardez la caméra pour vous connecter',
    'Visage reconnu',
    'Trop de tentatives',
    'Permission biométrique refusée',
    'Biométrie non disponible',
    'Authentification échouée',

    // ===== MESSAGES COMMUNS =====
    'Placez le code-barres dans le cadre',
    'Détails de la commande',
    'loading',
    'error',
    'success',
    'ok',
    'cancel',
    'done',
    'Ajouter',
    'Modifier',
    'Accueil',
    'PICK FROM GALLERY',
    'PICK FROM CAMERA',
    'Image non disponible',
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

      final translatedTexts = await _mlkitManager.translateMultiple(
        textList,
        newLanguage,
      );

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
    final translated = await _mlkitManager.translate(
      text,
      currentLanguage.value,
    );
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
