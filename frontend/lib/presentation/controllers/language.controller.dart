import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  static const _prefKey = 'app_language';

  // Langues supportées : code locale → label affiché
  static const Map<String, String> supportedLanguages = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
  };

  final currentLocale = 'fr'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey) ?? 'fr';
    currentLocale.value = saved;
  }

  Future<void> setLanguage(String langCode) async {
    if (!supportedLanguages.containsKey(langCode)) return;
    currentLocale.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
  }

  String get currentLabel =>
      supportedLanguages[currentLocale.value] ?? 'Français';

  bool get isRtl => currentLocale.value == 'ar';
}
