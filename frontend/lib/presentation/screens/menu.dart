import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    final translationProvider = Get.isRegistered<TranslationProvider>()
        ? Get.find<TranslationProvider>()
        : null;

    final colorScheme = Theme.of(context).colorScheme;

    return GetBuilder<LanguageController>(
      id: 'language',
      builder: (_) {
        final choices = [
          MenuItemData(
            titleKey: 'categories',
            subtitleKey: 'manage_categories',
            icon: Icons.category_rounded,
            iconBg: const Color(0xFF4F46E5),
            route: '/Categories',
          ),
          MenuItemData(
            titleKey: 'produits',
            subtitleKey: 'view_catalog',
            icon: Icons.shopping_bag_rounded,
            iconBg: const Color(0xFF0EA5E9),
            route: '/Products',
          ),
          MenuItemData(
            titleKey: 'documents',
            subtitleKey: 'my_docs',
            icon: Icons.description_rounded,
            iconBg: const Color(0xFFF59E0B),
            route: '/Documents',
          ),
          MenuItemData(
            titleKey: 'panier',
            subtitleKey: 'shopping_cart',
            icon: Icons.shopping_cart_rounded,
            iconBg: const Color(0xFF10B981),
            route: '/shopping',
          ),
          MenuItemData(
            titleKey: 'register',
            subtitleKey: 'create_account',
            icon: Icons.person_add_rounded,
            iconBg: const Color(0xFF8B5CF6),
            route: '/Subscribe',
          ),
          MenuItemData(
            titleKey: 'settings',
            subtitleKey: 'app_preferences',
            icon: Icons.settings_rounded,
            iconBg: const Color(0xFF64748B),
            route: '/settingsDetails',
          ),
        ];

        return Container(
          color: colorScheme.surface,
          child: CustomScrollView(
            slivers: [
              // ── Bannière d'accueil ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              colorScheme.primary.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.store_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translationProvider?.getTranslation('bienvenue') ??
                                    'bienvenue'.tr,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                'E-Commerce App',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.storefront_rounded,
                            color: Colors.white54, size: 30),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Titre section ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    translationProvider?.getTranslation('navigation') ??
                        'Navigation',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // ── Grille des cartes ──────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => SelectCard(
                      choice: choices[index],
                      translationProvider: translationProvider,
                    ),
                    childCount: choices.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Modèle de données ────────────────────────────────────────────────
class MenuItemData {
  const MenuItemData({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.iconBg,
    required this.route,
  });
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color iconBg;
  final String route;
}

// ─── Alias publique pour rétrocompatibilité (si importé ailleurs) ────
// ignore: unused_element
class Choice extends MenuItemData {
  const Choice({
    required super.titleKey,
    required super.subtitleKey,
    required super.icon,
    required Color colorB,
    required super.route,
  }) : super(iconBg: colorB);
}

// ── Carte individuelle ───────────────────────────────────────────────
class SelectCard extends StatelessWidget {
  const SelectCard({
    super.key,
    required this.choice,
    required this.translationProvider,
  });
  final MenuItemData choice;
  final TranslationProvider? translationProvider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: choice.iconBg.withValues(alpha: 0.08),
        highlightColor: choice.iconBg.withValues(alpha: 0.04),
        onTap: () => Navigator.of(context).pushNamed(choice.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFE2E8F0)
                  : colorScheme.outline,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icône ──────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: choice.iconBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(choice.icon, size: 22, color: choice.iconBg),
              ),
              const Spacer(),
              // ── Titre ──────────────────────────────────────────
              Text(
                translationProvider
                        ?.getTranslation(choice.titleKey) ??
                    choice.titleKey.tr,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // ── Sous-titre ─────────────────────────────────────
              Text(
                translationProvider
                        ?.getTranslation(choice.subtitleKey) ??
                    choice.subtitleKey.tr,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
