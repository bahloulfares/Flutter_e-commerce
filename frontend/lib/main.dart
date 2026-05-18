import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'package:atelier7/approuter.dart';
import 'package:atelier7/data/repositories/article.repository.dart';
import 'package:atelier7/data/repositories/categorie.repository.dart';
import 'package:atelier7/data/repositories/user.repository.dart';
import 'package:atelier7/data/repositories/order.repository.dart';
import 'package:atelier7/data/datasource/services/article_service.dart';
import 'package:atelier7/data/datasource/services/categorie.service.dart';
import 'package:atelier7/data/datasource/services/user.service.dart';
import 'package:atelier7/data/datasource/services/order.service.dart';
import 'package:atelier7/data/datasource/services/scategorie.service.dart';
import 'package:atelier7/data/repositories/scategorie.repository.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';
import 'package:atelier7/domain/usecases/article.usecase.dart';
import 'package:atelier7/domain/usecases/categorie.usecase.dart';
import 'package:atelier7/domain/usecases/user.usecase.dart';
import 'package:atelier7/domain/usecases/order.usecase.dart';
import 'package:atelier7/presentation/widgets/myappbar.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/presentation/controllers/order.controller.dart';
import 'package:atelier7/presentation/controllers/theme.controller.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';
import 'package:atelier7/utils/app_translations.dart';
import 'package:atelier7/presentation/screens/menu.dart';
import 'package:atelier7/presentation/widgets/mybottomnavbar.dart';
import 'package:atelier7/presentation/widgets/mydrawer.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les traductions
  final translations = await AppTranslations.load();

  // ⚙️ Charger les variables d'environnement (.env.dev par défaut)
  // Pour production, utilisez: --dart-define=ENV=prod
  const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
  try {
    await dotenv.load(fileName: '.env.$env');
  } catch (e) {
    developer.log('⚠️ Impossible de charger .env.$env: $e', name: 'main');
    developer.log('Utilisant les valeurs par défaut...', name: 'main');
    // Continuer sans le fichier .env - la constante aura sa valeur par défaut
  }

  // Initialiser le panier persistant sur toutes les plateformes.
  // Sur le web, cela ouvre la box Hive utilisée par le package.
  try {
    await PersistentShoppingCart().init();
    developer.log(
      kIsWeb
          ? '✅ Panier persistant initialisé sur le web'
          : '✅ Panier persistant initialisé sur mobile/desktop',
      name: 'main',
    );
  } catch (e) {
    developer.log('⚠️ Erreur init panier persistant: $e', name: 'main');
  }

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
  Get.put(ThemeController());
  Get.put(LanguageController());

  // 🎯 Initialiser le TranslationProvider (100% ML Kit)
  final translationProvider = Get.put(TranslationProvider());
  translationProvider.init(translations.keys);
  // Synchroniser ML Kit avec la langue courante du LanguageController
  await Get.find<LanguageController>().syncMlKitTranslation();

  Get.put(OrderService());
  Get.put(OrderRepository(orderService: Get.find()));
  Get.put(OrderUseCase(repository: Get.find()));
  Get.put(OrderController(useCase: Get.find()));

  Get.put(ScategorieService());
  Get.put(ScategorieRepository(scatService: Get.find()));
  Get.put(ScategorieController(repository: Get.find()));

  runApp(MyApp(translations: translations));
}

class MyApp extends StatelessWidget {
  final AppTranslations translations;
  const MyApp({super.key, required this.translations});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final langController = Get.find<LanguageController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        translations: translations,
        locale: Locale(langController.currentLocale.value),
        fallbackLocale: const Locale('fr'),
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xFF4F46E5),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFEDE9FE),
            onPrimaryContainer: const Color(0xFF3730A3),
            secondary: const Color(0xFF0EA5E9),
            surface: const Color(0xFFF8FAFC),
            onSurface: const Color(0xFF1E293B),
            onSurfaceVariant: const Color(0xFF64748B),
            surfaceContainerHighest: const Color(0xFFF1F5F9),
            surfaceContainer: const Color(0xFFF1F5F9),
            surfaceContainerLow: const Color(0xFFFFFFFF),
            outline: const Color(0xFFCBD5E1),
            error: const Color(0xFFEF4444),
          ),
          appBarTheme: AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            centerTitle: false,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF4F46E5),
            labelStyle: GoogleFonts.poppins(fontSize: 13),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE2E8F0),
            thickness: 1,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.dark,
          ).copyWith(
            primary: const Color(0xFF818CF8),
            onPrimary: const Color(0xFF1E1B4B),
            primaryContainer: const Color(0xFF3730A3),
            onPrimaryContainer: const Color(0xFFEDE9FE),
            surface: const Color(0xFF0F172A),
            onSurface: const Color(0xFFF1F5F9),
            onSurfaceVariant: const Color(0xFF94A3B8),
            surfaceContainerHighest: const Color(0xFF1E293B),
            surfaceContainer: const Color(0xFF1E293B),
            surfaceContainerLow: const Color(0xFF1E293B),
            outline: const Color(0xFF334155),
          ),
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: const Color(0xFF1E1B4B),
            foregroundColor: const Color(0xFFF1F5F9),
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF1F5F9),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF1E293B)),
            ),
            color: const Color(0xFF1E293B),
          ),
        ),
        themeMode: themeController.themeMode,
        initialRoute: '/',
        routes: appRoutes(),
        // ✅ Enlever const et wrapper dans un widget réactif
        home: const _AppHome(),
      ),
    );
  }
}

// ✅ Widget réactif qui rebuild quand la langue change
class _AppHome extends StatelessWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context) {
    final langController = Get.find<LanguageController>();

    return Obx(
      () {
        // Forcer rebuild de tout le Scaffold quand la langue change
        langController.currentLocale.value; // Watch pour changement

        return Scaffold(
          appBar: const MyAppBar(),
          body: const Menu(),
          drawer: const MyDrawer(),
          bottomNavigationBar: const Mybottomnavigationbar(),
        );
      },
    );
  }
}
