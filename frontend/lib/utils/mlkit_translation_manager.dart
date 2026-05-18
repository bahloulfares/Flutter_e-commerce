import 'dart:async';
import 'dart:developer' as developer;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// 🎯 Service ML Kit Singleton pour traduire TOUS les textes
/// - Gère le cache des traductions
/// - Gère les modèles ML Kit automatiquement
/// - Assure un seul traducteur par direction (lang_to_lang)
class MLKitTranslationManager {
  static final MLKitTranslationManager _instance = MLKitTranslationManager._();

  factory MLKitTranslationManager() {
    return _instance;
  }

  MLKitTranslationManager._();

  // Traducteurs en cache: "fr_en" => OnDeviceTranslator
  final Map<String, OnDeviceTranslator> _translators = {};

  // Cache des traductions: "fr_en_hello" => "bonjour"
  final Map<String, String> _translationCache = {};

  // Langage source par défaut
  String _sourceLanguage = 'fr';

  // Manager des modèles
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  // Mapping des langues
  static const Map<String, TranslateLanguage> _langMap = {
    'fr': TranslateLanguage.french,
    'en': TranslateLanguage.english,
    'ar': TranslateLanguage.arabic,
  };

  /// Définir la langue source (langue originale de l'app)
  void setSourceLanguage(String lang) {
    _sourceLanguage = lang;
    developer.log('🌐 Langue source définie à: $lang',
        name: 'MLKitTranslationManager');
  }

  /// Télécharger le modèle ML Kit pour une langue
  Future<bool> _downloadModel(TranslateLanguage lang) async {
    try {
      final downloaded = await _modelManager.isModelDownloaded(lang.bcpCode);
      if (downloaded) {
        developer.log('✅ Modèle ${lang.bcpCode} déjà téléchargé',
            name: 'MLKitTranslationManager');
        return true;
      }

      developer.log('⬇️ Téléchargement du modèle ${lang.bcpCode}...',
          name: 'MLKitTranslationManager');
      final success = await _modelManager.downloadModel(lang.bcpCode,
          isWifiRequired: false);

      if (success) {
        developer.log('✅ Modèle ${lang.bcpCode} téléchargé avec succès',
            name: 'MLKitTranslationManager');
      } else {
        developer.log('❌ Échec du téléchargement du modèle ${lang.bcpCode}',
            name: 'MLKitTranslationManager');
      }
      return success;
    } catch (e) {
      developer.log(
          '❌ Erreur lors du téléchargement du modèle ${lang.bcpCode}: $e',
          name: 'MLKitTranslationManager');
      return false;
    }
  }

  /// Obtenir ou créer un traducteur pour une direction (from_to)
  Future<OnDeviceTranslator?> _getOrCreateTranslator(
    TranslateLanguage fromLang,
    TranslateLanguage toLang,
  ) async {
    final key = '${fromLang.bcpCode}_${toLang.bcpCode}';

    // Retourner le traducteur en cache s'il existe
    if (_translators.containsKey(key)) {
      return _translators[key];
    }

    // Télécharger les modèles
    final fromOk = await _downloadModel(fromLang);
    final toOk = await _downloadModel(toLang);

    if (!fromOk || !toOk) {
      developer.log(
        '⚠️ Impossible de télécharger les modèles pour $key',
        name: 'MLKitTranslationManager',
      );
      return null;
    }

    // Créer le traducteur
    try {
      final translator = OnDeviceTranslator(
        sourceLanguage: fromLang,
        targetLanguage: toLang,
      );
      _translators[key] = translator;
      developer.log(
        '✅ Traducteur créé pour: $key',
        name: 'MLKitTranslationManager',
      );
      return translator;
    } catch (e) {
      developer.log(
        '❌ Erreur création traducteur: $e',
        name: 'MLKitTranslationManager',
      );
      return null;
    }
  }

  /// 🎯 FONCTION PRINCIPALE: Traduire un texte
  /// [text] - Le texte à traduire
  /// [targetLang] - Code langue cible (fr, en, ar)
  /// Retourne: Le texte traduit (ou original si erreur)
  Future<String> translate(String text, String targetLang) async {
    // ✅ Validation
    if (text.trim().isEmpty) return text;
    if (_sourceLanguage == targetLang) return text;

    // ✅ Vérifier le cache
    final cacheKey = '${_sourceLanguage}_${targetLang}_$text';
    if (_translationCache.containsKey(cacheKey)) {
      developer.log(
        '💾 Cache hit: "$text" → "${_translationCache[cacheKey]}"',
        name: 'MLKitTranslationManager',
      );
      return _translationCache[cacheKey]!;
    }

    // ✅ Obtenir les langues
    final sourceLang = _langMap[_sourceLanguage];
    final targetLangEnum = _langMap[targetLang];

    if (sourceLang == null || targetLangEnum == null) {
      developer.log(
        '❌ Langue inconnue: $_sourceLanguage ou $targetLang',
        name: 'MLKitTranslationManager',
      );
      return text;
    }

    // ✅ Obtenir le traducteur
    final translator = await _getOrCreateTranslator(sourceLang, targetLangEnum);
    if (translator == null) {
      developer.log(
        '❌ Impossible de créer le traducteur',
        name: 'MLKitTranslationManager',
      );
      return text;
    }

    // ✅ Traduire
    try {
      final translated = await translator
          .translateText(text)
          .timeout(const Duration(seconds: 15));

      // ✅ Stocker dans le cache
      _translationCache[cacheKey] = translated;

      developer.log(
        '✅ Traduction: "$text" → "$translated"',
        name: 'MLKitTranslationManager',
      );
      return translated;
    } catch (e) {
      developer.log(
        '❌ Erreur traduction: $e',
        name: 'MLKitTranslationManager',
      );
      return text; // Retourner le texte original en cas d'erreur
    }
  }

  /// Traduire PLUSIEURS textes en parallèle
  /// Utile pour traduire tout le menu en une seule requête
  Future<Map<String, String>> translateMultiple(
    List<String> texts,
    String targetLang,
  ) async {
    final results = <String, String>{};

    // Traduire tous les textes en parallèle
    final futures = texts.map((text) => translate(text, targetLang));
    final translations = await Future.wait(futures);

    // Créer le map résultat
    for (int i = 0; i < texts.length; i++) {
      results[texts[i]] = translations[i];
    }

    developer.log(
      '✅ ${texts.length} textes traduits en parallèle vers $targetLang',
      name: 'MLKitTranslationManager',
    );
    return results;
  }

  /// Vider le cache des traductions (quand langue source change)
  void clearCache() {
    _translationCache.clear();
    developer.log(
      '🗑️ Cache des traductions vidé',
      name: 'MLKitTranslationManager',
    );
  }

  /// Setter pour changer la langue source ET vider le cache
  void changeSourceLanguage(String newLang) {
    _sourceLanguage = newLang;
    clearCache();
    developer.log(
      '🔄 Langue source changée à: $newLang, cache vidé',
      name: 'MLKitTranslationManager',
    );
  }

  /// Nettoyer tous les traducteurs (pour fermer les ressources)
  Future<void> dispose() async {
    for (final translator in _translators.values) {
      try {
        await translator.close();
      } catch (_) {}
    }
    _translators.clear();
    _translationCache.clear();
    developer.log(
      '🛑 MLKitTranslationManager disposé',
      name: 'MLKitTranslationManager',
    );
  }
}
