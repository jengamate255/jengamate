import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/screens/order/order_details_screen.dart';
import 'package:jengamate/screens/order/order_screen.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/order_service.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'mocks.mocks.dart';

class MockUser extends Mock implements User {
  @override
  String get uid => 'test_user_id';
}

void main() {
  late MockAuthService mockAuthService;
  late MockOrderService mockOrderService;
  late MockPaymentService mockPaymentService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockOrderService = MockOrderService();
    mockPaymentService = MockPaymentService();
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: mockAuthService),
        Provider<OrderService>.value(value: mockOrderService),
        Provider<PaymentService>.value(value: mockPaymentService),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Order Screens', () {
    testWidgets('OrderScreen renders correctly', (WidgetTester tester) async {
      final mockUser = MockUser();
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockOrderService.getAllOrders()).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget(OrderScreen()));

      expect(find.text('Orders Management'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('OrderDetailsScreen renders correctly', (WidgetTester tester) async {
      final order = OrderModel(
        id: '123',
        status: OrderStatus.pending,
        totalAmount: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        buyerId: 'buyerId',
        supplierId: 'supplierId',
        customerId: 'customerId',
        customerName: 'customerName',
        supplierName: 'supplierName',
        items: [],
        paymentMethod: 'mpesa',
      );

      when(mockOrderService.getOrder('123')).thenAnswer((_) => Stream.value(order));
      when(mockPaymentService.getPaymentsForOrder('123')).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget(OrderDetailsScreen(orderId: '123')));

      await tester.pumpAndSettle();

      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Order ID: 123'), findsOneWidget);
    });
  });
}

