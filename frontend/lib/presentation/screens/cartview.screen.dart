import 'package:flutter/material.dart';
import 'package:atelier7/presentation/widgets/cart/showcartitem.widget.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: const CartViewItem(),
    );
  }
}
