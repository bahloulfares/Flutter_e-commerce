import 'package:flutter/material.dart';
import 'package:atelier7/presentation/widgets/cart/showcartitem.widget.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: const CartViewItem()
    );
  }
}
