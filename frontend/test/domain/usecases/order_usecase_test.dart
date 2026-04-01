import 'package:atelier7/data/datasource/services/order.service.dart';
import 'package:atelier7/data/repositories/order.repository.dart';
import 'package:atelier7/domain/usecases/order.usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FakeOrderService extends OrderService {
  String? capturedClient;
  List<Map<String, dynamic>>? capturedLineOrder;

  @override
  Future<Map<String, dynamic>> createOrder({
    required String client,
    required List<Map<String, dynamic>> lineOrder,
  }) async {
    capturedClient = client;
    capturedLineOrder = lineOrder
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);

    return {
      'order': {
        'id': 99,
        'client': client,
        'lineOrder': capturedLineOrder,
      },
    };
  }
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://127.0.0.1:3001/api');
  });

  test('placeOrder sends only articleId and quantity to repository', () async {
    final service = FakeOrderService();
    final repository = OrderRepository(orderService: service);
    final useCase = OrderUseCase(repository: repository);

    final response = await useCase.placeOrder(
      clientName: 'Smoke Test',
      items: [
        {
          'articleId': 7,
          'quantity': 3,
          'unitPrice': 499.99,
          'totalPrice': 0.01,
          'clientPhone': '12345678',
          'clientAddress': 'Tunis',
        },
      ],
    );

    expect(service.capturedClient, 'Smoke Test');
    expect(service.capturedLineOrder, [
      {
        'articleId': 7,
        'quantity': 3,
      },
    ]);
    expect(response['order']['lineOrder'], service.capturedLineOrder);
  });
}
