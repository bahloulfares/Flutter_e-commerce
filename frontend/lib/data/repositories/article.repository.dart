import 'dart:developer' as developer;
import 'package:atelier7/data/datasource/models/article.model.dart';
import 'package:atelier7/data/datasource/services/article_service.dart';

class ArticleRepository {
  final ArticleService artserv;

  ArticleRepository({required this.artserv});

//Affichage
  Future<List<Article?>?> getArticles() async {
    try {
      final articles = await artserv.getArticles();
      return articles.map((art) => Article.fromJson(art)).toList();
    } catch (error) {
      developer.log('Error: $error', name: 'ArticleRepository');
      return null;
    }
  }
}
