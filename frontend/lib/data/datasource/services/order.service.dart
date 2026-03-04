import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:atelier7/utils/constants.dart';
import 'package:atelier7/utils/error_handler.dart';

class OrderService {
  late Dio dio;

  OrderService() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
    dio = Dio(options);
  }

  // Create order
  Future<Map<String, dynamic>> createOrder({
    required String client,
    required List<Map<String, dynamic>> lineOrder,
  }) async {
    try {
      final response = await dio.post(
        '/orders',
        data: {
          'client': client,
          'lineOrder': lineOrder,
        },
      );

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }

      throw AppException('Failed to create order');
    } on DioException catch (e) {
      developer.log('Create order error: ${e.response?.data}',
          name: 'OrderService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      developer.log('Create order exception: $e', name: 'OrderService');
      throw AppException('Error creating order');
    }
  }

  // Get all orders
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await dio.get('/orders');

      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      throw AppException('Failed to load orders');
    } on DioException catch (e) {
      developer.log('Get orders error: ${e.response?.data}',
          name: 'OrderService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error loading orders');
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>> getOrderById(int id) async {
    try {
      final response = await dio.get('/orders/$id');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw AppException('Order not found');
    } on DioException catch (e) {
      developer.log('Get order error: ${e.response?.data}',
          name: 'OrderService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error loading order');
    }
  }

  // Update order status
  Future<Map<String, dynamic>> updateOrderStatus(int id, String status) async {
    try {
      final response = await dio.put(
        '/orders/$id',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw AppException('Failed to update order status');
    } on DioException catch (e) {
      developer.log('Update order error: ${e.response?.data}',
          name: 'OrderService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error updating order');
    }
  }

  // Delete order
  Future<void> deleteOrder(int id) async {
    try {
      final response = await dio.delete('/orders/$id');

      if (response.statusCode != 200) {
        throw AppException('Failed to delete order');
      }
    } on DioException catch (e) {
      developer.log('Delete order error: ${e.response?.data}',
          name: 'OrderService');
      throw AppException(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw AppException('Error deleting order');
    }
  }
}
