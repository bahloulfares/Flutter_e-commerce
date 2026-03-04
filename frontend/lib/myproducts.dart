import 'package:flutter/material.dart';

class Myproducts extends StatefulWidget {
  const Myproducts({super.key});

  @override
  State<Myproducts> createState() => _MyproductsState();
}

class _MyproductsState extends State<Myproducts> {
  int count = 0;
  List<String> images = [
    'assets/tel1.jpg',
    'assets/tel2.png',
    'assets/tel3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            "Image Numéro: ${count + 1}",
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Image.asset(
          images[count], // Utilisation correcte de `count` au lieu de `counter`
          width: 250,
          height: 250,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centrage des boutons
          children: [
            ElevatedButton(
              onPressed: _previousImage, // Correction des appels de fonction
              child: const Text('Précédent'),
            ),
            const SizedBox(width: 10), // Ajout d'un espacement entre les boutons
            ElevatedButton(
              onPressed: _nextImage, // Correction des appels de fonction
              child: const Text('Suivant'),
            ),
          ],
        )
      ],
    );
  }

  void _previousImage() {
    setState(() {
      if (count > 0) {
        count--; 
      }else{count=images.length-1;}
    });
  }

  void _nextImage() {
    setState(() {
      if (count < images.length - 1) {
        count++; 
      }else{count=0;}
    });
  }
}
