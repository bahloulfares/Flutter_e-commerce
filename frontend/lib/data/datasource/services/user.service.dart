import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:atelier7/utils/constants.dart';
import 'package:atelier7/utils/error_handler.dart';

class UserService {
  late Dio dio;

  UserService() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    );
    dio = Dio(options);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/users/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      throw AppException('Échec de connexion');
    } on DioException catch (e) {
      developer.log('Login error: ${e.response?.data}', name: 'UserService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur lors de la connexion');
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await dio.post(
        '/users/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': 'user',
          'avatar': '',
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      throw AppException('Échec de création de compte');
    } on DioException catch (e) {
      developer.log('Register error: ${e.response?.data}', name: 'UserService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur lors de l\'inscription');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        '/users/refreshToken',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      throw AppException('Impossible de rafraîchir le token');
    } on DioException catch (e) {
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur lors du rafraîchissement du token');
    }
  }
}
