import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:atelier7/utils/constants.dart';
import 'package:atelier7/utils/error_handler.dart';

class ArticleService {
  late Dio dio;

  ArticleService() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    );
    dio = Dio(options);
  }

  //Affichage
  Future<List<dynamic>> getArticles() async {
    try {
      Response response = await dio.get('/articles');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw AppException('Erreur lors de la récupération des articles');
      }
    } on DioException catch (e) {
      final errorMessage = ErrorHandler.handleDioError(e);
      developer.log('Erreur API Articles: $errorMessage',
          name: 'ArticleService');
      throw AppException(errorMessage);
    } catch (e) {
      developer.log('Erreur inattendue: $e', name: 'ArticleService');
      throw AppException('Erreur lors de la récupération des articles');
    }
  }
}
