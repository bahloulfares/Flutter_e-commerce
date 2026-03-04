import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/categorie.entity.dart';
import 'package:atelier7/domain/usecases/categorie.usecase.dart';

class CategorieController extends GetxController {
  final CategorieUseCase _useCase;

  var categoriesList = <CategorieEntity>[].obs;
  var isLoading = true.obs;
  var isPosting = false.obs;

  CategorieController({required CategorieUseCase useCase}) : _useCase = useCase;

  void fetchAllCategories() {
    _useCase.fetchCategories().then((data) {
      isLoading.value = false;
      if (data != null) {
        final result = data
            .map(
              (element) => CategorieEntity(
                id: element?.id ?? "",
                nomcategorie: element?.nomcategorie ?? "",
                imagecategorie: element?.imagecategorie ?? "",
              ),
            )
            .toList();

        categoriesList.value = result;
      }
    }).catchError((error) {});
  }

// Post a new category
  Future<void> postCategorie(String nom, dynamic image) async {
    try {
      isPosting.value = true;
      final newCategory = await _useCase.addCategorie(nom, image);
      if (newCategory != null) {
        categoriesList.add(newCategory);
      }
    } catch (error) {
      // Handle error (e.g., show a message)
      developer.log('Error posting category: $error',
          name: 'CategorieController');
    } finally {
      isPosting.value = false;
    }
  }

  // Suppression d'une catégorie
  Future<void> deleteCategorie(String id) async {
    try {
      isPosting.value = true;

      // Appeler la méthode du usecase pour supprimer la catégorie
      await _useCase.deleteCategorie(id);

      // Mettre à jour la liste des catégories en supprimant celle qui a été supprimée
      categoriesList.removeWhere((categorie) => categorie.id == id);
    } catch (error) {
      // Gérer les erreurs, afficher un message d'erreur
      developer.log('Erreur lors de la suppression de la catégorie: $error',
          name: 'CategorieController');
    } finally {
      isPosting.value = false;
    }
  }

// Mise à jour d'une catégorie
  Future<void> updateCategorie(String id, String nom, dynamic image) async {
    try {
      isPosting.value = true;

      // Appeler la méthode du usecase pour mettre à jour la catégorie
      final updatedCategory = await _useCase.updateCategorie(id, nom, image);

      // Si la mise à jour est réussie, mettre à jour la liste des catégories
      if (updatedCategory != null) {
        final index =
            categoriesList.indexWhere((categorie) => categorie.id == id);
        if (index != -1) {
          categoriesList[index] = updatedCategory;
          categoriesList.refresh(); // Actualiser la liste observable
        }
      }
    } catch (error) {
      // Gérer les erreurs, afficher un message d'erreur
      developer.log('Erreur lors de la mise à jour de la catégorie: $error',
          name: 'CategorieController');
    } finally {
      isPosting.value = false;
    }
  }
}
