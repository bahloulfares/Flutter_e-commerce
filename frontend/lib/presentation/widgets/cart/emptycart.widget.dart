import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';

class EmptyCartMsgWidget extends StatelessWidget {
  const EmptyCartMsgWidget({super.key});

  // 🔤 Helper function for translated text
  String tr(String key) {
    final translationProvider = Get.isRegistered<TranslationProvider>()
        ? Get.find<TranslationProvider>()
        : null;
    return translationProvider?.getTranslation(key) ?? key.tr;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GetBuilder<LanguageController>(
      id: 'language',
      builder: (_) => Center(
        child: SizedBox(
          height: size.height * .7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr('Panier vide')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(tr('Shop now')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
