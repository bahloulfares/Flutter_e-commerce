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
      if (response.statusCode == 200) {
        if (response.data is List) {
          developer.log('✅ Service: ${response.data.length} articles reçus',
              name: 'ArticleService');
          return response.data as List<dynamic>;
        } else {
          developer.log('⚠️ Service: Données reçues ne sont pas une Liste!',
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
}
