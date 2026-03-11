import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:atelier7/utils/constants.dart';
import 'package:atelier7/utils/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<Options> _authorizedOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.accessToken) ??
        prefs.getString(StorageKeys.token) ??
        '';

    return Options(
      headers: token.isNotEmpty
          ? {'Authorization': 'Bearer $token'}
          : <String, dynamic>{},
    );
  }

  Future<String?> _refreshAccessTokenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshTokenValue = prefs.getString(StorageKeys.refreshToken) ?? '';

    if (refreshTokenValue.isEmpty) {
      return null;
    }

    try {
      final response = await dio.post(
        '/users/refreshToken',
        data: {'refreshToken': refreshTokenValue},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['token']?.toString() ?? '';
        final newRefreshToken = data['refreshToken']?.toString() ?? '';

        if (newToken.isEmpty) {
          return null;
        }

        await prefs.setString(StorageKeys.accessToken, newToken);
        await prefs.setString(StorageKeys.token, newToken);
        if (newRefreshToken.isNotEmpty) {
          await prefs.setString(StorageKeys.refreshToken, newRefreshToken);
        }

        return newToken;
      }
    } catch (_) {
      return null;
    }

    return null;
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

  // Admin: get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await dio.get('/users');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      throw AppException('Erreur chargement utilisateurs');
    } on DioException catch (e) {
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur: $e');
    }
  }

  // Admin: update user role
  Future<Map<String, dynamic>> updateUserRole(int id, String role) async {
    try {
      final response = await dio.put('/users/$id/role', data: {'role': role});
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw AppException('Erreur modification rôle');
    } on DioException catch (e) {
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur: $e');
    }
  }

  // Admin: delete user
  Future<void> deleteUser(int id) async {
    try {
      await dio.delete('/users/$id');
    } on DioException catch (e) {
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await dio.get(
        '/users/me',
        options: await _authorizedOptions(),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      throw AppException('Erreur chargement profil');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final newToken = await _refreshAccessTokenIfNeeded();
        if (newToken != null && newToken.isNotEmpty) {
          final retryResponse = await dio.get(
            '/users/me',
            options: Options(headers: {'Authorization': 'Bearer $newToken'}),
          );

          if (retryResponse.statusCode == 200 &&
              retryResponse.data is Map<String, dynamic>) {
            return retryResponse.data as Map<String, dynamic>;
          }
        }
      }
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String avatar = '',
  }) async {
    try {
      final response = await dio.put(
        '/users/me',
        data: {
          'name': name,
          'email': email,
          'avatar': avatar,
        },
        options: await _authorizedOptions(),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      throw AppException('Erreur mise à jour profil');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final newToken = await _refreshAccessTokenIfNeeded();
        if (newToken != null && newToken.isNotEmpty) {
          final retryResponse = await dio.put(
            '/users/me',
            data: {
              'name': name,
              'email': email,
              'avatar': avatar,
            },
            options: Options(headers: {'Authorization': 'Bearer $newToken'}),
          );

          if (retryResponse.statusCode == 200 &&
              retryResponse.data is Map<String, dynamic>) {
            return retryResponse.data as Map<String, dynamic>;
          }
        }
      }
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Erreur: $e');
    }
  }
}
