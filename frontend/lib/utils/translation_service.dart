import 'dart:developer' as developer;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  final Map<String, OnDeviceTranslator> _cache = {};

  static const Map<String, TranslateLanguage> _langMap = {
    'fr': TranslateLanguage.french,
    'en': TranslateLanguage.english,
    'ar': TranslateLanguage.arabic,
  };

  /// Traduit [text] depuis [fromLang] vers [toLang]
  /// Utilise EN comme pivot si le modèle direct n'est pas disponible
  Future<String> translate(String text, String fromLang, String toLang) async {
    if (fromLang == toLang || text.trim().isEmpty) return text;

    final source = _langMap[fromLang];
    final target = _langMap[toLang];
    if (source == null || target == null) return text;

    // Essai direct
    final key = '${fromLang}_$toLang';
    _cache[key] ??= OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );

    try {
      final result = await _cache[key]!.translateText(text)
          .timeout(const Duration(seconds: 5));
      developer.log('✅ Traduction [$fromLang→$toLang]: "$text" → "$result"',
          name: 'TranslationService');
      return result;
    } catch (e) {
      developer.log('⚠️ Traduction directe échouée, essai via pivot EN: $e',
          name: 'TranslationService');

      // Pivot via EN si modèle direct indisponible
      try {
        if (fromLang != 'en' && toLang != 'en') {
          final toEn = OnDeviceTranslator(
            sourceLanguage: source,
            targetLanguage: TranslateLanguage.english,
          );
          final enText = await toEn.translateText(text)
              .timeout(const Duration(seconds: 5));
          final fromEn = OnDeviceTranslator(
            sourceLanguage: TranslateLanguage.english,
            targetLanguage: target,
          );
          return await fromEn.translateText(enText)
              .timeout(const Duration(seconds: 5));
        }
      } catch (e2) {
        developer.log('❌ Pivot EN aussi échoué: $e2', name: 'TranslationService');
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
      final manager = OnDeviceTranslatorModelManager();
      // isWifiRequired: false → autorise téléchargement sur données mobiles aussi
      final ok = await manager.downloadModel(lang.bcpCode, isWifiRequired: false);
      developer.log(
          ok
              ? '✅ Modèle ${lang.bcpCode} téléchargé'
              : '❌ Échec téléchargement ${lang.bcpCode}',
          name: 'TranslationService');
      return ok;
    } catch (e) {
      developer.log('❌ Exception downloadModel: $e', name: 'TranslationService');
      return false;
    }
  }

  /// Vérifie si le modèle est déjà téléchargé
  Future<bool> isModelDownloaded(String langCode) async {
    final lang = _langMap[langCode];
    if (lang == null) return false;
    try {
      final manager = OnDeviceTranslatorModelManager();
      final result = await manager.isModelDownloaded(lang.bcpCode);
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
