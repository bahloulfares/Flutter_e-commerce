import 'package:flutter/material.dart';
import 'package:atelier7/presentation/widgets/cart/carttitle.widget.dart';
import 'package:atelier7/presentation/widgets/cart/emptycart.widget.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

class CartViewItem extends StatefulWidget {
  const CartViewItem({super.key});

  @override
  State<CartViewItem> createState() => _CartViewState();
}

class _CartViewState extends State<CartViewItem> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Expanded(
              child: PersistentShoppingCart().showCartItems(
                cartItemsBuilder: (context, cartItems) {
                  if (cartItems.isEmpty) {
                    return const EmptyCartMsgWidget();
                  }

                  return ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return CartTitleWidget(data: item);
                    },
                  );
                },
              ),
            ),
            PersistentShoppingCart().showTotalAmountWidget(
              cartTotalAmountWidgetBuilder: (totalAmount) => Visibility(
                visible: totalAmount == 0.0 ? false : true,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                              color: Color.fromARGB(255, 113, 107, 107),
                              fontSize: 22),
                        ),
                        Text(
                          "$totalAmount TND",
                          style: const TextStyle(
                              color: Color.fromARGB(255, 143, 133, 133),
                              fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/checkout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Passer la commande',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
