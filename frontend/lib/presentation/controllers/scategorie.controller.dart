import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'package:atelier7/data/datasource/models/scategorie.model.dart';
import 'package:atelier7/data/repositories/scategorie.repository.dart';

class ScategorieController extends GetxController {
  final ScategorieRepository repository;

  ScategorieController({required this.repository});

  var scategoriesList = <Scategorie>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  Future<void> fetchAllScategories() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      scategoriesList.value = await repository.getAllScategories();
      developer.log('Fetched ${scategoriesList.length} scategories',
          name: 'ScategorieController');
    } catch (e) {
      errorMessage.value = 'Erreur chargement sous-catégories: $e';
      developer.log('Error: $e', name: 'ScategorieController');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchScategoriesByCategory(int categorieId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      scategoriesList.value =
          await repository.getScategoriesByCategory(categorieId);
    } catch (e) {
      errorMessage.value = 'Erreur chargement: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createScategorie(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final created = await repository.createScategorie(data);
      scategoriesList.add(created);
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur création: $e';
      developer.log('Create error: $e', name: 'ScategorieController');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateScategorie(int id, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final updated = await repository.updateScategorie(id, data);
      final index = scategoriesList.indexWhere((s) => s.id == id.toString());
      if (index != -1) {
        scategoriesList[index] = updated;
        scategoriesList.refresh();
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur modification: $e';
      developer.log('Update error: $e', name: 'ScategorieController');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteScategorie(int id) async {
    try {
      await repository.deleteScategorie(id);
      scategoriesList.removeWhere((s) => s.id == id.toString());
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur suppression: $e';
      developer.log('Delete error: $e', name: 'ScategorieController');
      return false;
    }
  }
}
