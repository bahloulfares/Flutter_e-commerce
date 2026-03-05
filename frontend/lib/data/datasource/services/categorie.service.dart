import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:atelier7/utils/constants.dart';
import 'package:atelier7/utils/error_handler.dart';

class CategorieService {
  late Dio dio;
  CategorieService() {
    developer.log('🔧 CategorieService: Configuration avec baseUrl = $baseUrl',
        name: 'CategorieService');
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    );
    dio = Dio(options);
  }
//Affichage
  Future<List<dynamic>> getCategories() async {
    try {
      developer.log('🌐 CategorieService: GET $baseUrl/categories',
          name: 'CategorieService');
      Response response = await dio.get('/categories');
      developer.log('📡 CategorieService: Status ${response.statusCode}',
          name: 'CategorieService');
      if (response.statusCode == 200) {
        if (response.data is List) {
          developer.log(
              '✅ CategorieService: ${response.data.length} catégories reçues',
              name: 'CategorieService');
          return response.data as List<dynamic>;
        } else {
          throw AppException('Format de réponse invalide');
        }
      } else {
        throw AppException('Erreur lors de la récupération des catégories');
      }
    } on DioException catch (e) {
      final errorMessage = ErrorHandler.handleDioError(e);
      developer.log('❌ Erreur API Catégories: $errorMessage',
          name: 'CategorieService');
      throw AppException(errorMessage);
    } catch (e) {
      developer.log('❌ Erreur inattendue: $e', name: 'CategorieService');
      throw AppException('Erreur lors de la récupération des catégories');
    }
  }

//Ajout
  Future<Map<String, dynamic>> postCategorie(String nom, dynamic image) async {
    var params = {
      "nomcategorie": nom,
      "imagecategorie": image,
    };
    Response response = await dio.post(
      '/categories',
      options: Options(headers: {
        HttpHeaders.contentTypeHeader: "application/json",
      }),
      data: jsonEncode(params),
    );
    return response.data;
  }

//suppression
  Future<String> deleteCategorie(String id) async {
    try {
      Response response = await dio.delete('/categories/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete data');
      }
// Supposons que la réponse contient un Map avec un champ "message"
//le backend retourne {message: categorie deleted successfully.}
      if (response.data is Map<String, dynamic>) {
        return response.data['message'] ?? 'Unknown error occurred';
      }
// Gestion des cas où response.data n'est pas un Map
      return response.data;
    } catch (e) {
      developer.log('Erreur lors de la suppression: $e',
          name: 'CategorieService');
      rethrow;
    }
  }

//update
  Future<Map<String, dynamic>> updateCategorie(
      String id, String nom, dynamic image) async {
    var params = {
      "nomcategorie": nom,
      "imagecategorie": image,
    };
    Response response = await dio.put(
      '/categories/$id',
      options: Options(headers: {
        HttpHeaders.contentTypeHeader: "application/json",
      }),
      data: jsonEncode(params),
    );
    return response.data;
  }
}
