import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'package:atelier7/domain/usecases/article.usecase.dart';

class ArticleController extends GetxController {
  final ArticleUseCase _useCase;

  var articlesList = <ArticleEntity>[].obs;
  var isLoading = false.obs;

  ArticleController({required ArticleUseCase useCase}) : _useCase = useCase;

  //Affichage
  void fetchAllArticles() {
    developer.log('🔄 Début du chargement des articles...',
        name: 'ArticleController');
    isLoading.value = true;
    _useCase.fetchArticles().then((data) {
      developer.log('✅ Données reçues: ${data?.length ?? 0} articles',
          name: 'ArticleController');
      isLoading.value = false;
      if (data != null) {
        // Utiliser directement les données du UseCase (pas de double mapping)
        articlesList.value = data.whereType<ArticleEntity>().toList();
        developer.log('📦 Articles ajoutés à la liste: ${articlesList.length}',
            name: 'ArticleController');
      } else {
        developer.log('⚠️ Data est null!', name: 'ArticleController');
      }
    }).catchError((error) {
      isLoading.value = false;
      developer.log('❌ Erreur lors du chargement des articles: $error',
          name: 'ArticleController');
    });
  }
}
