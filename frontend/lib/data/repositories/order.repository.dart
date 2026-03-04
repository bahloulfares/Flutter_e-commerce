import 'dart:developer' as developer;
import 'package:atelier7/data/datasource/services/order.service.dart';

class OrderRepository {
  final OrderService orderService;

  OrderRepository({required this.orderService});

  // Create a new order
  Future<Map<String, dynamic>> createOrder({
    required String client,
    required List<Map<String, dynamic>> lineOrder,
  }) async {
    try {
      final response = await orderService.createOrder(
        client: client,
        lineOrder: lineOrder,
      );
      developer.log('Order created: ${response['order']['id']}',
          name: 'OrderRepository');
      return response;
    } catch (e) {
      developer.log('Error creating order: $e', name: 'OrderRepository');
      rethrow;
    }
  }

  // Get all orders
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      return await orderService.getAllOrders();
    } catch (e) {
      developer.log('Error fetching orders: $e', name: 'OrderRepository');
      rethrow;
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>> getOrderById(int id) async {
    try {
      return await orderService.getOrderById(id);
    } catch (e) {
      developer.log('Error fetching order: $e', name: 'OrderRepository');
      rethrow;
    }
  }

  // Update order status
  Future<Map<String, dynamic>> updateOrderStatus(int id, String status) async {
    try {
      return await orderService.updateOrderStatus(id, status);
    } catch (e) {
      developer.log('Error updating order status: $e', name: 'OrderRepository');
      rethrow;
    }
  }

  // Delete order
  Future<void> deleteOrder(int id) async {
    try {
      await orderService.deleteOrder(id);
      developer.log('Order $id deleted', name: 'OrderRepository');
    } catch (e) {
      developer.log('Error deleting order: $e', name: 'OrderRepository');
      rethrow;
    }
  }
}
