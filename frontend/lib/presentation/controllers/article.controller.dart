import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'package:atelier7/domain/usecases/article.usecase.dart';

class ArticleController extends GetxController {
  final ArticleUseCase _useCase;

  var articlesList = <ArticleEntity>[].obs;
  var isLoading = true.obs;

  ArticleController({required ArticleUseCase useCase}) : _useCase = useCase;

  //Affichage
  void fetchAllArticles() {
    isLoading.value = true;
    _useCase.fetchArticles().then((data) {
      isLoading.value = false;
      if (data != null) {
        // Utiliser directement les données du UseCase (pas de double mapping)
        articlesList.value = data.whereType<ArticleEntity>().toList();
      }
    }).catchError((error) {
      isLoading.value = false;
      developer.log('Erreur lors du chargement des articles: $error',
          name: 'ArticleController');
    });
  }
}
