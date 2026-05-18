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

  // Ensemble de textes à traduire, alimenté dynamiquement
  final Set<String> _textSet = {};

  // Stockage local des traductions pour accès avant que GetMaterialApp ne monte
  Map<String, Map<String, String>> _allTranslations = {};

  @override
  void onInit() {
    super.onInit();
    _mlkitManager.setSourceLanguage(sourceLanguage.value);
    developer.log(
      '🚀 TranslationProvider initialisé. En attente des clés...',
      name: 'TranslationProvider',
    );
  }

  void init(Map<String, Map<String, String>> allTranslations) {
    _allTranslations = allTranslations;
    // Charge les clés
    final Map<String, String>? sourceTranslations = allTranslations[sourceLanguage.value];
    if (sourceTranslations != null) {
      _textSet.addAll(sourceTranslations.keys);
      developer.log('✅ ${_textSet.length} clés chargées dynamiquement', name: 'TranslationProvider');
    }

    // Charge les textes natifs
    translations.clear();
    if (sourceTranslations != null) {
      for (final key in _textSet) {
        translations[key] = sourceTranslations[key] ?? key;
      }
    } else {
      for (final key in _textSet) {
        translations[key] = key;
      }
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

      // Si on revient à la langue source ou si la langue cible existe dans les JSON, on utilise les JSON !
      // Cela évite de faire appel à ML Kit si on a déjà la traduction en dur.
      final targetTranslations = _allTranslations[newLanguage] ?? Get.translations[newLanguage];
      if (targetTranslations != null && targetTranslations.isNotEmpty) {
        translations.clear();
        for (final key in _textSet) {
          translations[key] = targetTranslations[key] ?? key;
        }
        developer.log(
          '✅ Langue $newLanguage chargée depuis les fichiers JSON natifs (${translations.length} clés)',
          name: 'TranslationProvider',
        );
        return; // ON ARRÊTE LÀ, PAS DE ML KIT SI ON A LE JSON !
      }

      // --- LOGIQUE FALLBACK ML KIT (si pas de JSON pour cette langue) ---

      // Étape 2: Si langue source change aussi, vider le cache
      if (sourceLanguage.value != newLanguage) {
        _mlkitManager.changeSourceLanguage(sourceLanguage.value);
      }

      // Étape 3: Traduire TOUS les textes en parallèle
      final textList = _textSet.toList();
      developer.log(
        '📝 Traduction de ${textList.length} textes vers $newLanguage via MLKit...',
        name: 'TranslationProvider',
      );

      // On traduit les VALEURS de la langue source, pas les CLÉS
      final sourceValuesList = textList.map((k) => Get.translations[sourceLanguage.value]?[k] ?? k).toList();
      final translatedValues = await _mlkitManager.translateMultiple(
        sourceValuesList,
        newLanguage,
      );

      // Étape 4: Mettre à jour la map réactive avec les nouvelles valeurs
      translations.clear();
      for (int i = 0; i < textList.length; i++) {
        translations[textList[i]] = translatedValues[sourceValuesList[i]] ?? textList[i];
      }

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
    // Fallback silencieux vers le système natif de GetX
    return key.tr;
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
