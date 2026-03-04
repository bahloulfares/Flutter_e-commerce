import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  final Size preferredSize = const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 31, 178, 219),
      title: const Text('Atelier7 Shop'),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () {
            Navigator.pushNamed(context, '/Products');
          },
        ),
        IconButton(
          icon: const Icon(Icons.category),
          tooltip: 'Categories',
          onPressed: () {
            Navigator.pushNamed(context, '/Categories');
          },
        ),
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Home',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        )
      ],
    );
  }
}
