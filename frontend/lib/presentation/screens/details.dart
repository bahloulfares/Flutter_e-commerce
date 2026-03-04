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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          myListElement.designation ?? 'Détails produit',
          style: const TextStyle(color: Colors.white),
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
                color: Colors.grey[100],
                child: myListElement.imageart != null
                    ? Image.network(
                        myListElement.imageart!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              size: 100, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.image_not_supported,
                        size: 100, color: Colors.grey),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),

                  if (myListElement.marque != null)
                    Text(
                      'Marque: ${myListElement.marque}',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500),
                    ),

                  const SizedBox(height: 20),

                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
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
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
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
                          color: const Color(0xFF6C63FF),
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
