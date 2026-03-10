import 'dart:developer' as developer;
import 'package:atelier7/data/datasource/models/scategorie.model.dart';
import 'package:atelier7/data/datasource/services/scategorie.service.dart';

class ScategorieRepository {
  final ScategorieService scatService;

  ScategorieRepository({required this.scatService});

  Future<List<Scategorie>> getAllScategories() async {
    try {
      return await scatService.getAllScategories();
    } catch (e) {
      developer.log('Error fetching scategories: $e',
          name: 'ScategorieRepository');
      rethrow;
    }
  }

  Future<List<Scategorie>> getScategoriesByCategory(int categorieId) async {
    try {
      return await scatService.getScategoriesByCategory(categorieId);
    } catch (e) {
      developer.log('Error fetching scategories by cat: $e',
          name: 'ScategorieRepository');
      rethrow;
    }
  }

  Future<Scategorie> createScategorie(Map<String, dynamic> data) async {
    try {
      return await scatService.createScategorie(data);
    } catch (e) {
      developer.log('Error creating scategorie: $e',
          name: 'ScategorieRepository');
      rethrow;
    }
  }

  Future<Scategorie> updateScategorie(int id, Map<String, dynamic> data) async {
    try {
      return await scatService.updateScategorie(id, data);
    } catch (e) {
      developer.log('Error updating scategorie: $e',
          name: 'ScategorieRepository');
      rethrow;
    }
  }

  Future<void> deleteScategorie(int id) async {
    try {
      await scatService.deleteScategorie(id);
    } catch (e) {
      developer.log('Error deleting scategorie: $e',
          name: 'ScategorieRepository');
      rethrow;
    }
  }
}
