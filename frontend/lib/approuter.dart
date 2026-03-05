import 'package:flutter/material.dart';
import 'package:atelier7/domain/entities/categorie.entity.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'package:atelier7/data/datasource/models/article.model.dart';
import 'package:atelier7/myproducts.dart';
import 'package:atelier7/presentation/screens/addcategorie.screen.dart';
import 'package:atelier7/presentation/screens/cartview.screen.dart';
import 'package:atelier7/presentation/screens/categorieslist.screen.dart';
import 'package:atelier7/presentation/screens/editcategorie.screen.dart';
import 'package:atelier7/presentation/screens/login.screen.dart';
import 'package:atelier7/presentation/screens/register.screen.dart';
import 'package:atelier7/presentation/screens/settings.screen.dart';
import 'package:atelier7/presentation/screens/details.dart';
import 'package:atelier7/presentation/screens/products.dart';
import 'package:atelier7/presentation/screens/checkout.screen.dart';
import 'package:atelier7/presentation/screens/order_confirmation.screen.dart';

Map<String, WidgetBuilder> appRoutes() {
  return {
    '/Documents': (context) => Scaffold(
          appBar: AppBar(
            title: const Text('My Products'),
          ),
          body: const Myproducts(),
        ),
    '/Subscribe': (context) => const Register(),
    '/Products': (context) => const Products(), // Route pour l'écran Products
    '/details': (context) {
      final arg = ModalRoute.of(context)!.settings.arguments;
      if (arg is Article) {
        return Details(myListElement: arg);
      }
      if (arg is ArticleEntity) {
        return Details(
          myListElement: Article(
            id: arg.id,
            designation: arg.designation,
            prix: arg.prix,
            qtestock: arg.qtestock,
            imageart: arg.imageart,
          ),
        );
      }
      return const Scaffold(
        body: Center(child: Text('Article invalide')),
      );
    },
    '/Categories': (context) =>
        const Categorieslist(), // Route pour l'écran Categories
    '/addcategories': (context) =>
        const Addcategorie(), // Route pour l'écran Addategorie
    '/editcategories': (context) {
      final categorie =
          ModalRoute.of(context)!.settings.arguments as CategorieEntity;
      return Editcategorie(categorie: categorie);
    }, // Route pour l'écran Editcategorie
    '/Settings': (context) => const Login(), // Route pour l'écran login
    '/register': (context) => const Register(), // Route pour l'écran register
    '/settingsDetails': (context) =>
        const SettingsScreen(), // Route pour l'écran SettingsScreen
    '/shopping': (context) =>
        const Products(), // Route pour l'écran produits (nouveau)
    '/cartView': (context) => const CartView(), // Route pour l'écran cart view
    '/checkout': (context) => const CheckoutScreen(), // Route pour checkout
    '/orderConfirmation': (context) =>
        const OrderConfirmationScreen(), // Route confirmation commande
  };
}
