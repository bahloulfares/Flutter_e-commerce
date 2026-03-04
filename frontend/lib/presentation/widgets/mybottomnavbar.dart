import 'package:flutter/material.dart';

class Mybottomnavigationbar extends StatelessWidget {
  const Mybottomnavigationbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            tooltip: 'Accueil',
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_filled),
          ),
          IconButton(
            tooltip: 'Catégories',
            onPressed: () => Navigator.pushNamed(context, '/Categories'),
            icon: const Icon(Icons.category),
          ),
          IconButton(
            tooltip: 'Panier',
            onPressed: () => Navigator.pushNamed(context, '/Products'),
            icon: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
    );
  }
}
