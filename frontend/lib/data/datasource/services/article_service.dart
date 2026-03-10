import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:atelier7/utils/constants.dart';
import 'package:atelier7/utils/error_handler.dart';

class ArticleService {
  late Dio dio;

  ArticleService() {
    developer.log('🔧 ArticleService: Configuration avec baseUrl = $baseUrl',
        name: 'ArticleService');
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    );
    dio = Dio(options);
  }

  //Affichage
  Future<List<dynamic>> getArticles() async {
    try {
      developer.log('🌐 Service: GET $baseUrl/articles',
          name: 'ArticleService');
      Response response = await dio.get('/articles');
      developer.log('📡 Service: Status ${response.statusCode}',
          name: 'ArticleService');
      developer.log(
          '📦 Service: Type de données reçu = ${response.data.runtimeType}',
          name: 'ArticleService');

      // Log raw response for debugging
      developer.log(
          '📋 Service: Réponse brute (premiers 500 caractères):\n${response.data.toString().substring(0, response.data.toString().length > 500 ? 500 : response.data.toString().length)}',
          name: 'ArticleService');

      if (response.statusCode == 200) {
        if (response.data is List) {
          developer.log('✅ Service: ${response.data.length} articles reçus',
              name: 'ArticleService');

          // Check if list is actually empty
          if ((response.data as List<dynamic>).isEmpty) {
            developer.log('⚠️ Service: Liste reçue est VIDE!',
                name: 'ArticleService');
          }

          return response.data as List<dynamic>;
        } else if (response.data is Map) {
          developer.log('⚠️ Service: Comme c\'est un Map, non une List!',
              name: 'ArticleService');
          developer.log(
              '📊 Service: Clés du Map: ${(response.data as Map).keys}',
              name: 'ArticleService');
          // If data is wrapped in an object, try to extract articles array
          final map = response.data as Map;
          if (map.containsKey('articles')) {
            developer.log('✅ Service: Trouvé clé "articles" dans la réponse',
                name: 'ArticleService');
            return (map['articles'] as List<dynamic>?) ?? [];
          } else if (map.containsKey('data')) {
            developer.log('✅ Service: Trouvé clé "data" dans la réponse',
                name: 'ArticleService');
            return (map['data'] as List<dynamic>?) ?? [];
          }
          throw AppException(
              'Format de réponse invalide - Map reçu mais pas de clé articles/data');
        } else {
          developer.log(
              '⚠️ Service: Type unexpected ${response.data.runtimeType}',
              name: 'ArticleService');
          throw AppException('Format de réponse invalide');
        }
      } else {
        throw AppException(
            'Erreur ${response.statusCode}: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMessage = ErrorHandler.handleDioError(e);
      developer.log(
          '❌ Erreur DioException: $errorMessage\n  Type: ${e.type}\n  Message: ${e.message}',
          name: 'ArticleService',
          error: e);
      throw AppException('Erreur réseau: $errorMessage');
    } catch (e, stackTrace) {
      developer.log('❌ Erreur inattendue: $e\n$stackTrace',
          name: 'ArticleService', error: e, stackTrace: stackTrace);
      throw AppException('Erreur: $e');
    }
  }

  // Create article
  Future<Map<String, dynamic>> createArticle(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/articles', data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw AppException('Erreur création article');
    } on DioException catch (e) {
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur: $e');
    }
  }

  // Update article
  Future<Map<String, dynamic>> updateArticle(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/articles/$id', data: data);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw AppException('Erreur modification article');
    } on DioException catch (e) {
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur: $e');
    }
  }

  // Delete article
  Future<void> deleteArticle(String id) async {
    try {
      await dio.delete('/articles/$id');
    } on DioException catch (e) {
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur: $e');
    }
  }
}
