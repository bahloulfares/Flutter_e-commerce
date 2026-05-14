import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';

class CartTitleWidget extends StatelessWidget {
  final PersistentShoppingCartItem data;

  CartTitleWidget({super.key, required this.data});

  final PersistentShoppingCart _shoppingCart = PersistentShoppingCart();

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
      builder: (_) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Image.network(
                data.productImages![0].toString(),
                width: 68,
                height: 68,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.productName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${data.unitPrice} ${tr('TND')}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            _shoppingCart
                                .removeFromCart(data.productId)
                                .then((removed) {
                              if (removed && context.mounted) {
                                showSnackBar(context, removed);
                              }
                            });
                          },
                          child: Container(
                            height: 30,
                            width: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colorScheme.error),
                            ),
                            child: Center(
                              child: Text(
                                tr('Supprimer'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.error,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      _shoppingCart.incrementCartItemQuantity(data.productId);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child:
                          Icon(Icons.add, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    data.quantity.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  InkWell(
                    onTap: () {
                      _shoppingCart.decrementCartItemQuantity(data.productId);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.remove,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSnackBar(BuildContext context, bool removed) {
    final snackBar = SnackBar(
      content: Text(
        removed
            ? tr('Product removed from cart.')
            : tr('Product not found in the cart.'),
      ),
      backgroundColor: removed ? Colors.red : Colors.green,
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
