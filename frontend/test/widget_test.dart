import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atelier7/presentation/widgets/cart/emptycart.widget.dart';

void main() {
  testWidgets('Empty cart widget shows message and call to action',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: EmptyCartMsgWidget()),
          ),
        ),
      ),
    );

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Shop now'), findsOneWidget);

    await tester.tap(find.text('Shop now'));
    await tester.pumpAndSettle();
  });
}
