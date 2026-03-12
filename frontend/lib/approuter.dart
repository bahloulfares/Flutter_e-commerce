import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/data/datasource/models/scategorie.model.dart';
import 'package:atelier7/presentation/screens/admin_orders.screen.dart';
import 'package:atelier7/presentation/screens/admin_articles.screen.dart';
import 'package:atelier7/presentation/screens/add_article.screen.dart';
import 'package:atelier7/presentation/screens/edit_article.screen.dart';
import 'package:atelier7/presentation/screens/admin_scategories.screen.dart';
import 'package:atelier7/presentation/screens/add_scategorie.screen.dart';
import 'package:atelier7/presentation/screens/edit_scategorie.screen.dart';
import 'package:atelier7/presentation/screens/admin_users.screen.dart';
import 'package:atelier7/presentation/screens/profile.screen.dart';

// Widget de protection pour les routes réservées aux admins
class AdminRouteGuard extends StatelessWidget {
  final Widget child;
  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      if (authController.isAdmin) {
        return child;
      }

      // Non-admin : afficher un message d'accès refusé
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accès refusé'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Accès réservé aux administrateurs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Votre rôle : ${authController.userRole.value.isEmpty ? "Invité" : authController.userRole.value}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// Widget de protection pour les routes nécessitant une authentification
class AuthRouteGuard extends StatelessWidget {
  final Widget child;
  const AuthRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      if (authController.isAuthenticated.value) {
        return child;
      }

      // Non authentifié : rediriger vers login
      return Scaffold(
        appBar: AppBar(
          title: const Text('Connexion requise'),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Veuillez vous connecter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vous devez être connecté pour accéder à cette fonctionnalité',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/Settings',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    });
  }
}

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
    '/Categories': (context) => const AdminRouteGuard(
          child: Categorieslist(),
        ), // Route pour l'écran Categories (admin seulement)
    '/addcategories': (context) => const AdminRouteGuard(
          child: Addcategorie(),
        ), // Route pour l'écran Addategorie (admin seulement)
    '/editcategories': (context) {
      final categorie =
          ModalRoute.of(context)!.settings.arguments as CategorieEntity;
      return AdminRouteGuard(
        child: Editcategorie(categorie: categorie),
      );
    }, // Route pour l'écran Editcategorie (admin seulement)
    '/Settings': (context) => const Login(), // Route pour l'écran login
    '/register': (context) => const Register(), // Route pour l'écran register
    '/settingsDetails': (context) =>
        const AuthRouteGuard(child: SettingsScreen()),
    '/profile': (context) => const AuthRouteGuard(child: ProfileScreen()),
    '/shopping': (context) => const Products(),
    '/cartView': (context) => const AuthRouteGuard(child: CartView()),
    '/checkout': (context) => const AuthRouteGuard(child: CheckoutScreen()),
    '/orderConfirmation': (context) =>
        const AuthRouteGuard(child: OrderConfirmationScreen()),
    // Admin routes
    '/admin/orders': (context) => const AdminRouteGuard(
          child: AdminOrdersScreen(),
        ),
    '/admin/articles': (context) => const AdminRouteGuard(
          child: AdminArticlesScreen(),
        ),
    '/admin/addArticle': (context) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      final initialReference = arg is String ? arg : null;
      return AdminRouteGuard(
        child: AddArticleScreen(initialReference: initialReference),
      );
    },
    '/admin/editArticle': (context) {
      final article =
          ModalRoute.of(context)!.settings.arguments as ArticleEntity;
      return AdminRouteGuard(
        child: EditArticleScreen(article: article),
      );
    },
    '/admin/scategories': (context) => const AdminRouteGuard(
          child: AdminScategoriesScreen(),
        ),
    '/admin/addScategorie': (context) => const AdminRouteGuard(
          child: AddScategorieScreen(),
        ),
    '/admin/editScategorie': (context) {
      final scat = ModalRoute.of(context)!.settings.arguments as Scategorie;
      return AdminRouteGuard(
        child: EditScategorieScreen(scategorie: scat),
      );
    },
    '/admin/users': (context) => const AdminRouteGuard(
          child: AdminUsersScreen(),
        ),
  };
}
