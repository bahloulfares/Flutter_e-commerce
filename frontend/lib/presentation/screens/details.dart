import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:atelier7/data/datasource/models/article.model.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/utils/translation_service.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

class Details extends StatefulWidget {
  final Article myListElement;

  const Details({super.key, required this.myListElement});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  final _translationService = TranslationService();
  final _langController = Get.find<LanguageController>();

  String? _translatedDesignation;
  String? _translatedMarque;
  bool _isTranslating = false;
  bool _isTranslated = false;

  @override
  void initState() {
    super.initState();
    // Écouter les changements de langue et relancer traduction auto
    _langController.addLanguageChangeListener(_onLanguageChanged);
  }

  void _onLanguageChanged(String newLocale) {
    // Quand la langue change, vider les traductions précédentes
    if (mounted) {
      setState(() {
        _translatedDesignation = null;
        _translatedMarque = null;
        _isTranslated = false;
      });
      // Relancer auto traduction si elle était active
      if (_isTranslated) {
        Future.delayed(const Duration(milliseconds: 500), _toggleTranslation);
      }
    }
  }

  Future<void> _toggleTranslation() async {
    if (_isTranslated) {
      setState(() {
        _translatedDesignation = null;
        _translatedMarque = null;
        _isTranslated = false;
      });
      return;
    }

    setState(() => _isTranslating = true);

    final targetLang = _langController.currentLocale.value;
    // Détecter la langue source (on suppose FR par défaut pour les produits)
    const sourceLang = 'fr';

    if (targetLang == sourceLang) {
      setState(() => _isTranslating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déjà dans la langue sélectionnée')),
      );
      return;
    }

    try {
      final designation = widget.myListElement.designation ?? '';
      final marque = widget.myListElement.marque ?? '';

      final results = await Future.wait([
        _translationService.translate(designation, sourceLang, targetLang),
        if (marque.isNotEmpty)
          _translationService.translate(marque, sourceLang, targetLang),
      ]);

      setState(() {
        _translatedDesignation = results[0];
        _translatedMarque = results.length > 1 ? results[1] : marque;
        _isTranslated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur traduction ML Kit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  @override
  void dispose() {
    _langController.removeLanguageChangeListener(_onLanguageChanged);
    _translationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final article = widget.myListElement;

    final displayDesignation =
        _translatedDesignation ?? article.designation ?? 'details'.tr;
    final displayMarque = _translatedMarque ?? article.marque;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text(
          displayDesignation,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Bouton traduction ML Kit
          Obx(() {
            final lang = _langController.currentLocale.value;
            if (lang == 'fr') return const SizedBox.shrink();
            return _isTranslating
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isTranslated ? Icons.translate : Icons.g_translate,
                      color: _isTranslated
                          ? Colors.yellowAccent
                          : colorScheme.onPrimary,
                    ),
                    tooltip: _isTranslated
                        ? 'Afficher original'
                        : 'Traduire avec ML Kit',
                    onPressed: _toggleTranslation,
                  );
          }),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cartView'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Hero(
              tag: article.id ?? '',
              child: Container(
                width: double.infinity,
                height: 350,
                color: colorScheme.surfaceContainerLowest,
                child: article.imageart != null
                    ? Image.network(
                        article.imageart!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          color: colorScheme.surfaceContainer,
                          child: Icon(
                            Icons.broken_image,
                            size: 100,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ),

            // Badge "traduit par ML Kit"
            if (_isTranslated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: colorScheme.secondaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.translate,
                      size: 14,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Traduit par ML Kit · ${_langController.currentLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleTranslation,
                      child: Text(
                        'Original',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayDesignation,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (article.reference != null)
                    Text(
                      '${'reference'.tr}: ${article.reference}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (displayMarque != null)
                    Text(
                      '${'marque'.tr}: $displayMarque',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sell_rounded,
                            color: colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${'prix'.tr}:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${article.prix?.toStringAsFixed(2) ?? '0.00'} TND',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (article.qtestock ?? 0) > 0
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (article.qtestock ?? 0) > 0
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (article.qtestock ?? 0) > 0
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: (article.qtestock ?? 0) > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              (article.qtestock ?? 0) > 0
                                  ? '${'en_stock'.tr}: ${article.qtestock}'
                                  : 'rupture'.tr,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (article.qtestock ?? 0) > 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: PersistentShoppingCart().showAndUpdateCartItemWidget(
                      inCartWidget: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded,
                                  color: Color(0xFFEF4444), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'retirer_panier'.tr,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      notInCartWidget: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: colorScheme.primary,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_shopping_cart_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ajouter_panier'.tr,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      product: PersistentShoppingCartItem(
                        productId: article.id ?? '',
                        productName: article.designation ?? 'Produit',
                        unitPrice: article.prix?.toDouble() ?? 0.0,
                        productImages: [article.imageart ?? ''],
                        quantity: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
