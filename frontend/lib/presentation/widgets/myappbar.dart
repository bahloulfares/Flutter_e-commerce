import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  final Size preferredSize = const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final translationProvider = Get.isRegistered<TranslationProvider>()
        ? Get.find<TranslationProvider>()
        : null;

    String tr(String key) {
      if (translationProvider != null) {
        return translationProvider.getTranslation(key);
      }
      return key.tr;
    }

    return GetBuilder<LanguageController>(
      id: 'language',
      builder: (_) {
        return AppBar(
          backgroundColor: const Color.fromARGB(255, 31, 178, 219),
          title: Text(
            tr('boutique'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: tr('panier'),
              onPressed: () {
                Navigator.pushNamed(context, '/Products');
              },
            ),
            IconButton(
              icon: const Icon(Icons.category),
              tooltip: tr('categories'),
              onPressed: () {
                Navigator.pushNamed(context, '/Categories');
              },
            ),
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: tr('accueil'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            )
          ],
        );
      },
    );
  }
}
