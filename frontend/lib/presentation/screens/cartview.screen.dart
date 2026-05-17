import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/widgets/cart/showcartitem.widget.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  // 🔤 Helper function for translated text
  String tr(String key) {
    final translationProvider = Get.isRegistered<TranslationProvider>()
        ? Get.find<TranslationProvider>()
        : null;
    return translationProvider?.getTranslation(key) ?? key.tr;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GetBuilder<LanguageController>(
      id: 'language',
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(
            tr('panier'),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary,
            ),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        body: const CartViewItem(),
      ),
    );
  }
}
