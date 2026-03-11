import 'package:flutter/material.dart';
import 'package:atelier7/data/datasource/models/article.model.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

class Details extends StatelessWidget {
  final Article myListElement;

  const Details({
    super.key,
    required this.myListElement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text(
          myListElement.designation ?? 'Détails produit',
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        actions: [
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
            // Product Image
            Hero(
              tag: myListElement.id ?? '',
              child: Container(
                width: double.infinity,
                height: 350,
                color: colorScheme.surfaceContainerLowest,
                child: myListElement.imageart != null
                    ? Image.network(
                        myListElement.imageart!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colorScheme.surfaceContainer,
                          child: Icon(Icons.broken_image,
                              size: 100, color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : Icon(Icons.image_not_supported,
                        size: 100, color: colorScheme.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 20),

            // Product Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    myListElement.designation ?? 'Produit',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Reference & Brand
                  if (myListElement.reference != null)
                    Text(
                      'Réf: ${myListElement.reference}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                  if (myListElement.marque != null)
                    Text(
                      'Marque: ${myListElement.marque}',
                      style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500),
                    ),

                  const SizedBox(height: 20),

                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Prix:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${myListElement.prix?.toStringAsFixed(2) ?? '0.00'} TND',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stock Status
                  Row(
                    children: [
                      Icon(
                        myListElement.qtestock != null &&
                                myListElement.qtestock! > 0
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: myListElement.qtestock != null &&
                                myListElement.qtestock! > 0
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        myListElement.qtestock != null &&
                                myListElement.qtestock! > 0
                            ? 'En stock: ${myListElement.qtestock} unités'
                            : 'Rupture de stock',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: myListElement.qtestock != null &&
                                  myListElement.qtestock! > 0
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Add to Cart Button
                  Center(
                    child: PersistentShoppingCart().showAndUpdateCartItemWidget(
                      inCartWidget: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.red,
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Retirer du panier',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      notInCartWidget: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.primary,
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Ajouter au panier',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      product: PersistentShoppingCartItem(
                        productId: myListElement.id ?? '',
                        productName: myListElement.designation ?? 'Produit',
                        unitPrice: myListElement.prix?.toDouble() ?? 0.0,
                        productImages: [myListElement.imageart ?? ''],
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
