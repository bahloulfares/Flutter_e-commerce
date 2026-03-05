import 'dart:developer' as developer;
import 'package:atelier7/data/datasource/models/categories.model.dart';
import 'package:atelier7/data/datasource/services/categorie.service.dart';

class CategorieRepository {
  final CategorieService catserv;

  CategorieRepository({required this.catserv});

  Future<List<Categorie>> getCategories() async {
    developer.log('📥 CategorieRepository: Appel du service...',
        name: 'CategorieRepository');
    try {
      final categories = await catserv.getCategories();
      developer.log(
          '📦 CategorieRepository: ${categories.length} catégories reçues',
          name: 'CategorieRepository');
      final mapped = categories.map((c) {
        developer.log('🔧 CategorieRepository: Mapping ${c['nomcategorie']}',
            name: 'CategorieRepository');
        return Categorie.fromJson(c);
      }).toList();
      developer.log(
          '✅ CategorieRepository: ${mapped.length} catégories mappées',
          name: 'CategorieRepository');
      return mapped;
    } catch (e, stackTrace) {
      developer.log('❌ CategorieRepository Error: $e\n$stackTrace',
          name: 'CategorieRepository', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map> postCategorie(String nom, dynamic image) async {
    final categorie = await catserv.postCategorie(nom, image);
    return categorie;
  }

  //Suppression
  Future<String> deleteCategorie(String id) async {
    try {
      final response = await catserv.deleteCategorie(id);
      developer.log('Response $response', name: 'CategorieRepository');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  //modification
  Future<Map> updateCategorie(String id, String nom, dynamic image) async {
    final categorie = await catserv.updateCategorie(id, nom, image);
    return categorie;
  }
}
