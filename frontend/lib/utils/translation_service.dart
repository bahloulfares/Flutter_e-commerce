import 'dart:developer' as developer;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  final Map<String, OnDeviceTranslator> _cache = {};
  String _lastLanguage = '';

  static const Map<String, TranslateLanguage> _langMap = {
    'fr': TranslateLanguage.french,
    'en': TranslateLanguage.english,
    'ar': TranslateLanguage.arabic,
  };

  final OnDeviceTranslatorModelManager _manager =
      OnDeviceTranslatorModelManager();

  /// Vérifie si la langue a changé et vide le cache si nécessaire
  void _checkLanguageChanged(String toLang) {
    if (_lastLanguage.isNotEmpty && _lastLanguage != toLang) {
      developer.log('🔄 Langue changée: $_lastLanguage → $toLang, cache vidé',
          name: 'TranslationService');
      _clearCache();
    }
    _lastLanguage = toLang;
  }

  /// Vide le cache des traducteurs (pour redémarrage après changement de langue)
  void _clearCache() {
    for (final t in _cache.values) {
      try {
        t.close();
      } catch (_) {}
    }
    _cache.clear();
  }

  Future<bool> _ensureModel(TranslateLanguage lang) async {
    try {
      final downloaded = await _manager.isModelDownloaded(lang.bcpCode);
      if (downloaded) return true;
      developer.log(
          '⬇️ Modèle ${lang.bcpCode} non trouvé, tentative de téléchargement...',
          name: 'TranslationService');
      return await _manager.downloadModel(lang.bcpCode, isWifiRequired: false);
    } catch (e) {
      developer.log('❌ Erreur ensureModel ${lang.bcpCode}: $e',
          name: 'TranslationService');
      return false;
    }
  }

  /// Traduit [text] depuis [fromLang] vers [toLang]
  /// Utilise EN comme pivot si le modèle direct n'est pas disponible
  Future<String> translate(String text, String fromLang, String toLang) async {
    if (fromLang == toLang || text.trim().isEmpty) return text;

    // Vérifier si la langue cible a changé (reload cache si nécessaire)
    _checkLanguageChanged(toLang);

    final source = _langMap[fromLang];
    final target = _langMap[toLang];
    if (source == null || target == null) return text;

    final key = '${fromLang}_$toLang';

    // Assurer que les modèles sont présents (si possible)
    final srcOk = await _ensureModel(source);
    final tgtOk = await _ensureModel(target);

    if (!srcOk || !tgtOk) {
      developer.log(
          '⚠️ Un ou plusieurs modèles manquent ($fromLang,$toLang). Tentative pivot EN si possible.',
          name: 'TranslationService');
    }

    // (Re)créer le traducteur si nécessaire
    _cache[key] ??= OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );

    try {
      // Augmenter timeout car la traduction locale peut prendre plus que 5s
      final result = await _cache[key]!
          .translateText(text)
          .timeout(const Duration(seconds: 15));
      developer.log('✅ Traduction [$fromLang→$toLang]: "$text" → "$result"',
          name: 'TranslationService');
      return result;
    } catch (e) {
      developer.log('⚠️ Traduction directe échouée: $e',
          name: 'TranslationService');
      // Fermer et retirer le traducteur du cache pour forcer recréation ultérieure
      try {
        await _cache[key]?.close();
      } catch (_) {}
      _cache.remove(key);

      // Pivot via EN si possible
      if (fromLang != 'en' && toLang != 'en') {
        final pivotSrc = source;
        final pivotTgt = target;
        try {
          // Assurer modèle anglais
          await _ensureModel(TranslateLanguage.english);

          OnDeviceTranslator? toEn;
          OnDeviceTranslator? fromEn;
          try {
            toEn = OnDeviceTranslator(
                sourceLanguage: pivotSrc,
                targetLanguage: TranslateLanguage.english);
            final enText = await toEn
                .translateText(text)
                .timeout(const Duration(seconds: 15));

            fromEn = OnDeviceTranslator(
                sourceLanguage: TranslateLanguage.english,
                targetLanguage: pivotTgt);
            final finalText = await fromEn
                .translateText(enText)
                .timeout(const Duration(seconds: 15));

            return finalText;
          } finally {
            try {
              await toEn?.close();
            } catch (_) {}
            try {
              await fromEn?.close();
            } catch (_) {}
          }
        } catch (e2) {
          developer.log('❌ Pivot EN aussi échoué: $e2',
              name: 'TranslationService');
        }
      }

      return text;
    }
  }

  /// Télécharge le modèle ML Kit — isWifiRequired: false pour autoriser données mobiles
  Future<bool> downloadModel(String langCode) async {
    final lang = _langMap[langCode];
    if (lang == null) {
      developer.log('❌ Langue inconnue: $langCode', name: 'TranslationService');
      return false;
    }
    developer.log('⬇️ Début téléchargement modèle: ${lang.bcpCode}',
        name: 'TranslationService');
    try {
      final ok =
          await _manager.downloadModel(lang.bcpCode, isWifiRequired: false);
      developer.log(
          ok
              ? '✅ Modèle ${lang.bcpCode} téléchargé'
              : '❌ Échec téléchargement ${lang.bcpCode}',
          name: 'TranslationService');
      return ok;
    } catch (e) {
      developer.log('❌ Exception downloadModel: $e',
          name: 'TranslationService');
      return false;
    }
  }

  /// Vérifie si le modèle est déjà téléchargé
  Future<bool> isModelDownloaded(String langCode) async {
    final lang = _langMap[langCode];
    if (lang == null) return false;
    try {
      final result = await _manager.isModelDownloaded(lang.bcpCode);
      developer.log('🔍 Modèle ${lang.bcpCode} disponible: $result',
          name: 'TranslationService');
      return result;
    } catch (e) {
      developer.log('❌ Exception isModelDownloaded: $e',
          name: 'TranslationService');
      return false;
    }
  }

  void dispose() {
    for (final t in _cache.values) {
      t.close();
    }
    _cache.clear();
  }
}
