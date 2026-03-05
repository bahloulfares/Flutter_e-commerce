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
      developer.log('❌ Repository Error: $error',
          name: 'ArticleRepository', error: error, stackTrace: stackTrace);
      return null;
    }
  }
}
