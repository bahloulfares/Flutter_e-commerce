import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:atelier7/utils/constants.dart';
import 'package:atelier7/utils/error_handler.dart';
import 'package:atelier7/data/datasource/models/scategorie.model.dart';

class ScategorieService {
  late Dio dio;

  ScategorieService() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    );
    dio = Dio(options);
  }

  // Get all subcategories
  Future<List<Scategorie>> getAllScategories() async {
    try {
      final response = await dio.get('/scategories');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => Scategorie.fromJson(json))
            .toList();
      }

      throw AppException('Failed to load subcategories');
    } on DioException catch (e) {
      developer.log('Get scategories error: ${e.response?.data}',
          name: 'ScategorieService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error loading subcategories');
    }
  }

  // Get subcategories by category ID
  Future<List<Scategorie>> getScategoriesByCategory(int categorieId) async {
    try {
      final response = await dio.get('/scategories/cat/$categorieId');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => Scategorie.fromJson(json))
            .toList();
      }

      throw AppException('Failed to load subcategories for category');
    } on DioException catch (e) {
      developer.log('Get scategories by category error: ${e.response?.data}',
          name: 'ScategorieService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error loading subcategories');
    }
  }

  // Get subcategory by ID
  Future<Scategorie> getScategorieById(int id) async {
    try {
      final response = await dio.get('/scategories/$id');

      if (response.statusCode == 200) {
        return Scategorie.fromJson(response.data);
      }

      throw AppException('Subcategory not found');
    } on DioException catch (e) {
      developer.log('Get scategorie error: ${e.response?.data}',
          name: 'ScategorieService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error loading subcategory');
    }
  }

  // Create subcategory
  Future<Scategorie> createScategorie(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/scategories', data: data);

      if (response.statusCode == 201) {
        return Scategorie.fromJson(response.data);
      }

      throw AppException('Failed to create subcategory');
    } on DioException catch (e) {
      developer.log('Create scategorie error: ${e.response?.data}',
          name: 'ScategorieService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error creating subcategory');
    }
  }

  // Update subcategory
  Future<Scategorie> updateScategorie(int id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/scategories/$id', data: data);

      if (response.statusCode == 200) {
        return Scategorie.fromJson(response.data);
      }

      throw AppException('Failed to update subcategory');
    } on DioException catch (e) {
      developer.log('Update scategorie error: ${e.response?.data}',
          name: 'ScategorieService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error updating subcategory');
    }
  }

  // Delete subcategory
  Future<void> deleteScategorie(int id) async {
    try {
      final response = await dio.delete('/scategories/$id');

      if (response.statusCode != 200) {
        throw AppException('Failed to delete subcategory');
      }
    } on DioException catch (e) {
      developer.log('Delete scategorie error: ${e.response?.data}',
          name: 'ScategorieService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error deleting subcategory');
    }
  }
}
