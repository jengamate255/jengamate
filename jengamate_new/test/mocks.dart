import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/order_service.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  AuthService,
  OrderService,
  DatabaseService,
  PaymentService,
])
void main() {}
