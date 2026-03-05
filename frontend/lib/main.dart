import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:atelier7/approuter.dart';
import 'package:atelier7/data/repositories/article.repository.dart';
import 'package:atelier7/data/repositories/categorie.repository.dart';
import 'package:atelier7/data/repositories/user.repository.dart';
import 'package:atelier7/data/repositories/order.repository.dart';
import 'package:atelier7/data/datasource/services/article_service.dart';
import 'package:atelier7/data/datasource/services/categorie.service.dart';
import 'package:atelier7/data/datasource/services/user.service.dart';
import 'package:atelier7/data/datasource/services/order.service.dart';
import 'package:atelier7/domain/usecases/article.usecase.dart';
import 'package:atelier7/domain/usecases/categorie.usecase.dart';
import 'package:atelier7/domain/usecases/user.usecase.dart';
import 'package:atelier7/domain/usecases/order.usecase.dart';
import 'package:atelier7/presentation/widgets/myappbar.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/presentation/controllers/order.controller.dart';
import 'package:atelier7/presentation/screens/menu.dart';
import 'package:atelier7/presentation/widgets/mybottomnavbar.dart';
import 'package:atelier7/presentation/widgets/mydrawer.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

void main() async {
  // ⚙️ Charger les variables d'environnement (.env.dev par défaut)
  // Pour production, utilisez: --dart-define=ENV=prod
  const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
  try {
    await dotenv.load(fileName: '.env.$env');
  } catch (e) {
    print('⚠️ Impossible de charger .env.$env: $e');
    print('   Utilisant les valeurs par défaut...');
    // Continuer sans le fichier .env - la constante aura sa valeur par défaut
  }

  //Initialiser shoppingCart
  await PersistentShoppingCart().init();

  //injection articles getx
  Get.put(ArticleService());
  Get.put(ArticleRepository(artserv: Get.find()));
  Get.put(ArticleUseCase(respository: Get.find()));
  Get.put(ArticleController(useCase: Get.find()));

  Get.put(CategorieService());
  Get.put(CategorieRepository(catserv: Get.find()));
  Get.put(CategorieUseCase(respository: Get.find()));
  Get.put(CategorieController(useCase: Get.find()));

  Get.put(UserService());
  Get.put(UserRepository(userService: Get.find()));
  Get.put(AuthenticateUserUseCase(repository: Get.find()));
  Get.put(AuthController(userUseCase: Get.find()));

  Get.put(OrderService());
  Get.put(OrderRepository(orderService: Get.find()));
  Get.put(OrderUseCase(repository: Get.find()));
  Get.put(OrderController(useCase: Get.find()));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Changed from MaterialApp to GetMaterialApp for GetX navigation
      debugShowCheckedModeBanner: false, //bch na7ina echalta l7amra
      initialRoute: '/',
      routes: appRoutes(),
      home: const Scaffold(
        appBar: MyAppBar(),
        body: Menu(),
        drawer: MyDrawer(),
        bottomNavigationBar: Mybottomnavigationbar(),
      ),
    );
  }
}
