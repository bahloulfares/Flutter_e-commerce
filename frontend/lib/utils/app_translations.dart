import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  final Map<String, Map<String, String>> _translations;

  AppTranslations(this._translations);

  @override
  Map<String, Map<String, String>> get keys => _translations;

  static Future<AppTranslations> load() async {
    final Map<String, Map<String, String>> translations = {};
    for (final lang in ['fr', 'en', 'ar']) {
      final jsonStr =
          await rootBundle.loadString('assets/translations/$lang.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      translations[lang] = jsonMap.map((k, v) => MapEntry(k, v.toString()));
    }
    return AppTranslations(translations);
  }
}
