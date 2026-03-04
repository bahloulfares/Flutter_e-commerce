import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: choices.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (context, index) {
          return SelectCard(choice: choices[index]);
        },
      ),
    );
  }
}

class Choice {
  const Choice({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorB,
    required this.route,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color colorB;
  final String route;
}

const List<Choice> choices = [
  Choice(
    title: 'Catégories',
    subtitle: 'Gérer les catégories',
    icon: Icons.category,
    colorB: Colors.green,
    route: '/Categories',
  ),
  Choice(
    title: 'Produits',
    subtitle: 'Voir le catalogue',
    icon: Icons.shopping_bag,
    colorB: Colors.red,
    route: '/Products',
  ),
  Choice(
    title: 'Documents',
    subtitle: 'Mes produits docs',
    icon: Icons.description,
    colorB: Colors.orange,
    route: '/Documents',
  ),
  Choice(
    title: 'Panier',
    subtitle: 'Shopping cart',
    icon: Icons.shopping_cart,
    colorB: Colors.blue,
    route: '/shopping',
  ),
  Choice(
    title: 'Inscription',
    subtitle: 'Créer un compte',
    icon: Icons.person_add,
    colorB: Colors.purple,
    route: '/Subscribe',
  ),
  Choice(
    title: 'Paramètres',
    subtitle: 'Préférences app',
    icon: Icons.settings,
    colorB: Colors.grey,
    route: '/settingsDetails',
  ),
];

class SelectCard extends StatelessWidget {
  const SelectCard({super.key, required this.choice});
  final Choice choice;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      splashColor: choice.colorB.withValues(alpha: .2),
      onTap: () => Navigator.of(context).pushNamed(choice.route),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: choice.colorB.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(choice.icon, size: 28, color: choice.colorB),
              ),
              const Spacer(),
              Text(
                choice.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                choice.subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
