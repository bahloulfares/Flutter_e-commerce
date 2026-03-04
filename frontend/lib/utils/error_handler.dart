import 'package:dio/dio.dart';

/// Classe pour gérer les exceptions de l'application
class AppException implements Exception {
  final String message;
  final String? details;

  AppException(this.message, [this.details]);

  @override
  String toString() => details != null ? '$message: $details' : message;
}

/// Gestion centralisée des erreurs
class ErrorHandler {
  /// Convertit une erreur Dio en message utilisateur
  static String handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Délai de connexion dépassé. Vérifiez votre connexion internet.';
      case DioExceptionType.sendTimeout:
        return "Délai d'envoi dépassé. Veuillez réessayer.";
      case DioExceptionType.receiveTimeout:
        return 'Délai de réception dépassé. Le serveur met trop de temps à répondre.';
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Requête annulée.';
      case DioExceptionType.connectionError:
        return 'Erreur de connexion. Vérifiez votre connexion internet.';
      default:
        return 'Une erreur inattendue est survenue.';
    }
  }

  /// Gère les codes de statut HTTP
  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide. Vérifiez les données envoyées.';
      case 401:
        return 'Non autorisé. Veuillez vous connecter.';
      case 403:
        return "Accès interdit. Vous n'avez pas les permissions nécessaires.";
      case 404:
        return 'Ressource non trouvée.';
      case 500:
        return 'Erreur serveur. Veuillez réessayer plus tard.';
      case 503:
        return 'Service indisponible. Veuillez réessayer plus tard.';
      default:
        return 'Erreur HTTP: $statusCode';
    }
  }

  /// Gère toutes les erreurs génériques
  static String handleError(dynamic error) {
    if (error is DioException) {
      return handleDioError(error);
    } else if (error is AppException) {
      return error.message;
    } else {
      return 'Une erreur inattendue est survenue: ${error.toString()}';
    }
  }
}

/// Helper pour afficher les messages d'erreur dans l'UI
class ErrorMessage {
  static const String networkError = 'Erreur de connexion réseau';
  static const String serverError = 'Erreur du serveur';
  static const String unknownError = 'Une erreur inconnue est survenue';
  static const String authError = 'Erreur d\'authentification';
  static const String validationError = 'Erreur de validation';

  // Messages spécifiques
  static const String usernameRequired = 'Le nom d\'utilisateur est requis';
  static const String passwordRequired = 'Le mot de passe est requis';
  static const String loginFailed =
      'Nom d\'utilisateur ou mot de passe incorrect';
  static const String registrationFailed = 'Échec de l\'inscription';
  static const String userAlreadyExists = 'Cet utilisateur existe déjà';
}
