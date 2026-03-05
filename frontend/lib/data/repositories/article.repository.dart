import 'dart:developer' as developer;
import 'package:atelier7/data/datasource/models/article.model.dart';
import 'package:atelier7/data/datasource/services/article_service.dart';

class ArticleRepository {
  final ArticleService artserv;

  ArticleRepository({required this.artserv});

//Affichage
  Future<List<Article?>?> getArticles() async {
    try {
      developer.log('📥 Repository: Appel du service...',
          name: 'ArticleRepository');
      final articles = await artserv.getArticles();
      developer.log('📦 Repository: ${articles.length} articles bruts reçus',
          name: 'ArticleRepository');

      final mappedArticles = articles.map((art) {
        developer.log('🔧 Repository: Mapping ${art['designation']}',
            name: 'ArticleRepository');
        return Article.fromJson(art);
      }).toList();

      developer.log('✅ Repository: ${mappedArticles.length} articles mappés',
          name: 'ArticleRepository');
      return mappedArticles;
    } catch (error, stackTrace) {
      developer.log(
          '❌ Repository EXCEPTION: $error\n📋 Type: ${error.runtimeType}\n📊 StackTrace:\n$stackTrace',
          name: 'ArticleRepository',
          error: error,
          stackTrace: stackTrace);

      // Identify error type for better logging
      String errorType = error.toString();
      if (errorType.contains('SocketException') ||
          errorType.contains('Connection refused')) {
        developer.log('🔴 Network Error - Cannot connect to server',
            name: 'ArticleRepository');
      } else if (errorType.contains('TimeoutException') ||
          errorType.contains('timed out')) {
        developer.log('🔴 Connection Timeout', name: 'ArticleRepository');
      } else if (errorType.contains('DioException')) {
        developer.log('🔴 Dio HTTP Error', name: 'ArticleRepository');
      } else if (errorType.contains('FormatException') ||
          errorType.contains('parsing')) {
        developer.log('🔴 JSON Parsing Error - réponse invalide',
            name: 'ArticleRepository');
      }

      // IMPORTANT: Lance l'exception au lieu de retourner null
      // Cela permet aux layers supérieurs d'attraper l'erreur
      rethrow;
    }
  }
}
