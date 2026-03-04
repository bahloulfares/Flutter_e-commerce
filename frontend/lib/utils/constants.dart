import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration globale de l'application
///
/// Utilise flutter_dotenv pour charger la configuration depuis .env files
/// - Développement: .env.dev (chargé par défaut)
/// - Production: .env.prod (lancez avec --dart-define=ENV=prod)
String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3001/api';

/// Environnement actuel
String get currentEnv => dotenv.env['APP_ENV'] ?? 'development';

/// Configuration de l'API
class ApiConfig {
  // Timeouts
  static const int connectionTimeout = 5; // secondes
  static const int receiveTimeout = 5; // secondes

  // Endpoints
  static const String articlesEndpoint = '/articles';
  static const String categoriesEndpoint = '/categories';
  static const String usersEndpoint = '/users';

  // Messages
  static const String noInternetMessage = 'Pas de connexion internet';
  static const String serverErrorMessage = 'Erreur du serveur';
}

/// Configuration de l'application
class AppConfig {
  static const String appName = 'Atelier7 E-commerce';
  static const String appVersion = '1.0.0+1';

  // Database
  static const String databaseName = 'app.db';
  static const int databaseVersion = 1;

  // Validation
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;

  // UI
  static const int itemsPerPage = 20;
  static const int maxImageSizeMB = 5;
}

/// Clés de stockage local
class StorageKeys {
  static const String userId = 'user_id';
  static const String username = 'username';
  static const String email = 'email';
  static const String isLoggedIn = 'is_logged_in';
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String cartItems = 'cart_items';
  static const String theme = 'theme';
  static const String language = 'language';
}

/// Messages d'erreur communs
class ErrorMessages {
  static const String networkError = 'Erreur de connexion réseau';
  static const String serverError = 'Erreur du serveur';
  static const String unknownError = 'Une erreur inconnue est survenue';
  static const String validationError = 'Erreur de validation';
  static const String notFoundError = 'Ressource non trouvée';
}
