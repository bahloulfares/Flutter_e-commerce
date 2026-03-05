import 'package:atelier7/data/repositories/article.repository.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'dart:developer' as developer;

class ArticleUseCase {
  final ArticleRepository _respository;

  ArticleUseCase({required ArticleRepository respository})
      : _respository = respository;

  Future<List<ArticleEntity?>?> fetchArticles() async {
    developer.log('🔍 UseCase: Appel du repository...', name: 'ArticleUseCase');

    try {
      final result = await _respository.getArticles();
      developer.log('📥 UseCase: Résultat reçu - ${result?.length ?? 0} items',
          name: 'ArticleUseCase');

      final data = result?.map((element) {
        developer.log('🔧 Mapping article: ${element?.designation}',
            name: 'ArticleUseCase');
        return ArticleEntity(
          id: element?.id ?? "",
          designation: element?.designation ?? "",
          prix: element?.prix ?? 0,
          qtestock: element?.qtestock ?? 0,
          imageart: element?.imageart ?? "",
        );
      }).toList();

      developer.log('✅ UseCase: ${data?.length ?? 0} entités créées',
          name: 'ArticleUseCase');
      return data;
    } catch (e, stackTrace) {
      developer.log('❌ UseCase ERROR: $e\n$stackTrace',
          name: 'ArticleUseCase', error: e, stackTrace: stackTrace);
      // Relancer l'exception pour que le controller la reçoive
      rethrow;
    }
  }
}
