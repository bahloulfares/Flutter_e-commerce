import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

class ArticlesListWidget extends StatelessWidget {
  final ArticleEntity articles;

  ArticlesListWidget({super.key, required this.articles});
  //on a enlevé const car : Can't define the 'const' constructor because the field 'controller' is initialized with a non-constant value.

  final controller = Get.find<ArticleController>();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Image.network(
                  articles.imageart.toString(),
                  width: 68,
                  height: 68,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        articles.designation,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 104, 103, 103)),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        "${articles.prix} TND",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PersistentShoppingCart()
                            .showAndUpdateCartItemWidget(
                          inCartWidget: Container(
                            height: 30,
                            width: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Center(
                              child: Text(
                                'Remove',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                          notInCartWidget: Container(
                            height: 30,
                            width: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Center(
                                child: Text(
                                  'Add to cart',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                          product: PersistentShoppingCartItem(
                              productId: articles.id,
                              productName: articles.designation,
                              unitPrice: articles.prix!.toDouble(),
                              productImages: [
                                articles.imageart!
                              ], // Mettre l'image dans une liste
                              quantity: 1),
                        ),
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
