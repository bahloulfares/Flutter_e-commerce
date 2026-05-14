import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';

class Mybottomnavigationbar extends StatelessWidget {
  const Mybottomnavigationbar({super.key});

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
        return BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: tr('accueil'),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home_filled),
              ),
              IconButton(
                tooltip: tr('categories'),
                onPressed: () => Navigator.pushNamed(context, '/Categories'),
                icon: const Icon(Icons.category),
              ),
              IconButton(
                tooltip: tr('panier'),
                onPressed: () => Navigator.pushNamed(context, '/Products'),
                icon: const Icon(Icons.shopping_cart),
              ),
            ],
          ),
        );
      },
    );
  }
}
