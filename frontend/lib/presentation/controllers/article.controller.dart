import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'package:atelier7/domain/usecases/article.usecase.dart';

class ArticleController extends GetxController {
  final ArticleUseCase _useCase;

  var articlesList = <ArticleEntity>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  ArticleController({required ArticleUseCase useCase}) : _useCase = useCase;

  //Affichage
  void fetchAllArticles() {
    developer.log('🔄 Début du chargement des articles...',
        name: 'ArticleController');
    isLoading.value = true;
    errorMessage.value = '';

    _useCase.fetchArticles().then((data) {
      developer.log('✅ Données reçues: ${data?.length ?? 0} articles',
          name: 'ArticleController');
      isLoading.value = false;

      if (data == null || data.isEmpty) {
        developer.log('⚠️ Data est null ou vide!', name: 'ArticleController');
        // Enhanced error message
        errorMessage.value = '''Impossible de charger les articles.

🔍 DIAGNOSTIC:
✓ Téléphone IP: 172.16.41.3
✓ PC IP: 172.16.42.95 
✓ Les deux sont sur le même Wi-Fi

SOLUTIONS À ESSAYER:
1️⃣ Vérifier le Pare-feu Windows:
   - Ouvrir Paramètres > Sécurité
   - Autoriser le port 3001
   
2️⃣ Vérifier le serveur backend:
   - Vérifier qu'il tourne
   - Vérifier qu'il écoute le port 3001
   
3️⃣ Test manuellement:
   - Sur ton téléphone, ouvre un navigateur
   - Va à: http://172.16.42.95:3001/api/articles
   - Si ça marche, c'est un problème d'app
   - Si ça ne marche pas, c'est réseau/firewall

Erreur: Données vides du serveur''';
        articlesList.value = [];
      } else {
        try {
          // Utiliser directement les données du UseCase (pas de double mapping)
          final filtered = data.whereType<ArticleEntity>().toList();
          developer.log(
              '📦 Articles filtrés: ${filtered.length}/${data.length}',
              name: 'ArticleController');
          articlesList.value = filtered;

          if (filtered.isEmpty) {
            errorMessage.value = '''Erreur: Articles reçus mais invalides.
Des données ont été reçues mais elles ne sont pas valides.
Vérifiez le format API.''';
          } else {
            errorMessage.value = '';
            developer.log('✅ ${filtered.length} articles chargés avec succès',
                name: 'ArticleController');
          }
        } catch (e) {
          developer.log('❌ Erreur filtrage: $e', name: 'ArticleController');
          errorMessage.value = 'Erreur de traitement: $e';
        }
      }
    }).catchError((error, stackTrace) {
      isLoading.value = false;
      developer.log('❌ ERREUR COMPLÈTE: $error\n$stackTrace',
          name: 'ArticleController', error: error, stackTrace: stackTrace);

      String networkError = error.toString();
      if (networkError.contains('SocketException') ||
          networkError.contains('Connection refused')) {
        errorMessage.value =
            '''Impossible de se connecter au serveur (172.16.42.95:3001)

Le téléphone ne peut pas atteindre le PC:
✓ Vérifiez que vous êtes sur le même Wi-Fi
✓ Le serveur écoute sur le port 3001
✓ Aucun pare-feu ne bloque la connexion

Détails: ${networkError.substring(0, 80)}''';
      } else if (networkError.contains('timed out') ||
          networkError.contains('Timeout')) {
        errorMessage.value =
            'Délai d\'attente dépassé - Le serveur met trop de temps à répondre';
      } else {
        errorMessage.value = 'Erreur réseau: $error';
      }
      articlesList.value = [];
    });
  }
}
