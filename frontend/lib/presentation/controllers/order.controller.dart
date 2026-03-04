import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'package:atelier7/domain/usecases/order.usecase.dart';

class OrderController extends GetxController {
  final OrderUseCase useCase;

  OrderController({required this.useCase});

  var isLoading = false.obs;
  var ordersList = <Map<String, dynamic>>[].obs;
  var currentOrder = Rxn<Map<String, dynamic>>();
  var errorMessage = ''.obs;

  // Place order from cart
  Future<bool> placeOrder({
    required String clientName,
    required String clientPhone,
    required String clientAddress,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Add client info to first item for display
      final enrichedItems = cartItems.map((item) {
        return {
          ...item,
          'clientPhone': clientPhone,
          'clientAddress': clientAddress,
        };
      }).toList();

      final response = await useCase.placeOrder(
        clientName: clientName,
        items: enrichedItems,
      );

      if (response['order'] != null) {
        currentOrder.value = response['order'];
        developer.log('Order placed successfully: ${response['order']['id']}',
            name: 'OrderController');
        return true;
      }

      errorMessage.value = 'Échec de la commande';
      return false;
    } catch (e) {
      errorMessage.value = 'Erreur: ${e.toString()}';
      developer.log('Error placing order: $e', name: 'OrderController');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch all orders
  Future<void> fetchAllOrders() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final orders = await useCase.fetchAllOrders();
      ordersList.value = orders;

      developer.log('Fetched ${orders.length} orders', name: 'OrderController');
    } catch (e) {
      errorMessage.value = 'Erreur de chargement des commandes';
      developer.log('Error fetching orders: $e', name: 'OrderController');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch order details
  Future<void> fetchOrderDetails(int orderId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final order = await useCase.fetchOrderDetails(orderId);
      currentOrder.value = order;

      developer.log('Fetched order details: $orderId', name: 'OrderController');
    } catch (e) {
      errorMessage.value = 'Commande introuvable';
      developer.log('Error fetching order details: $e',
          name: 'OrderController');
    } finally {
      isLoading.value = false;
    }
  }

  // Clear current order
  void clearCurrentOrder() {
    currentOrder.value = null;
    errorMessage.value = '';
  }

  // Get order total
  double getOrderTotal(Map<String, dynamic> order) {
    return (order['total'] ?? 0).toDouble();
  }

  // Get order status color
  String getStatusColor(String status) {
    switch (status) {
      case 'Not processed':
        return 'orange';
      case 'Processing':
        return 'blue';
      case 'Shipped':
        return 'purple';
      case 'Delivered':
        return 'green';
      case 'Cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }
}
