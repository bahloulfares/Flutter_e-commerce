import 'package:get/get.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:atelier7/presentation/controllers/translation_provider.dart';

class LanguageController extends GetxController {
  static const _prefKey = 'app_language';

  // Langues supportées : code locale → label affiché
  static const Map<String, String> supportedLanguages = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
  };

  final currentLocale = 'fr'.obs;
  final isLanguageChanging =
      false.obs; // Pour showing loading indicator pendant transition

  // Callback pour notifier quand la langue change
  final List<Function(String newLocale)> _languageChangeListeners = [];

  @override
  void onInit() {
    super.onInit();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey) ?? 'fr';
    currentLocale.value = saved;

    if (Get.isRegistered<TranslationProvider>()) {
      await Get.find<TranslationProvider>().setLanguage(saved);
    }

    update(['language']);
  }

  /// Synchronise le provider ML Kit avec la langue courante.
  Future<void> syncMlKitTranslation() async {
    if (!Get.isRegistered<TranslationProvider>()) return;
    await Get.find<TranslationProvider>().setLanguage(currentLocale.value);
  }

  /// Register a listener pour être notifié du changement de langue
  void addLanguageChangeListener(Function(String newLocale) callback) {
    _languageChangeListeners.add(callback);
  }

  /// Remove un listener
  void removeLanguageChangeListener(Function(String newLocale) callback) {
    _languageChangeListeners.remove(callback);
  }

  /// Notifie tous les listeners du changement de langue
  void _notifyLanguageChange(String newLang) {
    for (final listener in _languageChangeListeners) {
      try {
        listener(newLang);
      } catch (e) {
        developer.log('❌ Erreur listener language change: $e',
            name: 'LanguageController');
      }
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (!supportedLanguages.containsKey(langCode)) return;
    if (currentLocale.value == langCode) return; // Pas de changement

    isLanguageChanging.value = true;

    try {
      currentLocale.value = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
      
      Get.updateLocale(Locale(langCode));

      if (Get.isRegistered<TranslationProvider>()) {
        await Get.find<TranslationProvider>().setLanguage(langCode);
      }

      update(['language']);

      // Notifier tous les listeners
      _notifyLanguageChange(langCode);

      // Wait a bit pour assurer transition fluide
      await Future.delayed(const Duration(milliseconds: 300));
    } finally {
      isLanguageChanging.value = false;
    }
  }

  String get currentLabel =>
      supportedLanguages[currentLocale.value] ?? 'Français';

  bool get isRtl => currentLocale.value == 'ar';

  @override
  void onClose() {
    _languageChangeListeners.clear();
    super.onClose();
  }
}
