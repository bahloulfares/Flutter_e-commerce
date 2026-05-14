import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    final translationProvider = Get.isRegistered<TranslationProvider>()
        ? Get.find<TranslationProvider>()
        : null;

    return GetBuilder<LanguageController>(
      id: 'language',
      builder: (_) {
        final choices = [
          Choice(
            titleKey: 'categories',
            subtitleKey: 'manage_categories',
            icon: Icons.category,
            colorB: Colors.green,
            route: '/Categories',
          ),
          Choice(
            titleKey: 'products',
            subtitleKey: 'view_catalog',
            icon: Icons.shopping_bag,
            colorB: Colors.red,
            route: '/Products',
          ),
          Choice(
            titleKey: 'documents',
            subtitleKey: 'my_docs',
            icon: Icons.description,
            colorB: Colors.orange,
            route: '/Documents',
          ),
          Choice(
            titleKey: 'cart',
            subtitleKey: 'shopping_cart',
            icon: Icons.shopping_cart,
            colorB: Colors.blue,
            route: '/shopping',
          ),
          Choice(
            titleKey: 'register',
            subtitleKey: 'create_account',
            icon: Icons.person_add,
            colorB: Colors.purple,
            route: '/Subscribe',
          ),
          Choice(
            titleKey: 'settings',
            subtitleKey: 'app_preferences',
            icon: Icons.settings,
            colorB: Colors.grey,
            route: '/settingsDetails',
          ),
        ];

        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            itemCount: choices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              return SelectCard(
                choice: choices[index],
                translationProvider: translationProvider,
              );
            },
          ),
        );
      },
    );
  }
}

class Choice {
  const Choice({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.colorB,
    required this.route,
  });
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color colorB;
  final String route;
}

class SelectCard extends StatelessWidget {
  const SelectCard({
    super.key,
    required this.choice,
    required this.translationProvider,
  });
  final Choice choice;
  final TranslationProvider? translationProvider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      splashColor: choice.colorB.withValues(alpha: .2),
      onTap: () => Navigator.of(context).pushNamed(choice.route),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: choice.colorB.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(choice.icon, size: 28, color: choice.colorB),
              ),
              const Spacer(),
              Text(
                translationProvider?.getTranslation(choice.titleKey) ??
                    choice.titleKey.tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                translationProvider?.getTranslation(choice.subtitleKey) ??
                    choice.subtitleKey.tr,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
