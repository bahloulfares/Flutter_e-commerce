import 'package:atelier7/data/repositories/order.repository.dart';

class OrderUseCase {
  final OrderRepository repository;

  OrderUseCase({required this.repository});

  // Create order from cart items
  Future<Map<String, dynamic>> placeOrder({
    required String clientName,
    required List<Map<String, dynamic>> items,
  }) async {
    // Transform cart items to line order format
    final lineOrder = items.map((item) {
      return {
        'articleId': item['articleId'],
        'quantity': item['quantity'],
        'totalPrice': (item['unitPrice'] * item['quantity']),
      };
    }).toList();

    return await repository.createOrder(
      client: clientName,
      lineOrder: lineOrder,
    );
  }

  // Get all user orders
  Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    return await repository.getAllOrders();
  }

  // Get specific order details
  Future<Map<String, dynamic>> fetchOrderDetails(int orderId) async {
    return await repository.getOrderById(orderId);
  }

  // Update order status (for admin)
  Future<Map<String, dynamic>> updateStatus(
      int orderId, String newStatus) async {
    return await repository.updateOrderStatus(orderId, newStatus);
  }

  // Cancel order
  Future<void> cancelOrder(int orderId) async {
    await repository.deleteOrder(orderId);
  }
}
