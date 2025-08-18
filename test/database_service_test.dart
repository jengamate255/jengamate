import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:jengamate/models/enums/transaction_enums.dart';
import 'package:jengamate/models/message_model.dart';
import 'package:jengamate/models/enums/message_enums.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockDocumentReference extends Mock implements DocumentReference {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  late DatabaseService databaseService;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockDocumentReference;
  late MockDocumentSnapshot mockDocumentSnapshot;

  setUp(() {
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();
    mockDocumentSnapshot = MockDocumentSnapshot();
    databaseService = DatabaseService();
  });

  group('DatabaseService', () {
    test('upsertUser sets user data in Firestore', () async {
      // Arrange
      final user = UserModel(
          uid: 'testUid',
          firstName: 'Test',
          lastName: 'User',
          email: 'test@example.com');
      when(mockFirebaseFirestore.collection('users') as dynamic)
          .thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc('testUid'))
          .thenReturn(mockDocumentReference);
      when(mockDocumentReference.set(user.toMap(), SetOptions(merge: true)))
          .thenAnswer((_) async {});

      // Act
      //await databaseService.upsertUser(user);
      await databaseService.updateUser(user.toMap());

      // Assert
      verify(mockFirebaseFirestore.collection('users')).called(1);
      verify(mockCollectionReference.doc('testUid')).called(1);
      verify(mockDocumentReference.set(user.toMap(), SetOptions(merge: true)))
          .called(1);
    });

    test('getUser returns UserModel from Firestore', () async {
      // Arrange
      when(mockFirebaseFirestore.collection('users') as dynamic)
          .thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc('testUid'))
          .thenReturn(mockDocumentReference);
      when(mockDocumentReference.get())
          .thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn({
        'email': 'test@example.com',
        'firstName': 'Test',
        'lastName': 'User',
        'role': 'engineer'
      });

      // Act
      final userMap = await databaseService.getUser('testUid');
      final user = userMap != null ? UserModel.fromJson(userMap) : null;

      // Assert
      expect(user, isA<UserModel>());
      expect(user!.uid, 'testUid');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Test');
      expect(user.lastName, 'User');
    });
  });

   group('OrderModel', () {
     test('createOrder creates an order in Firestore', () async {
       final order = OrderModel(
         id: 'order1',
         buyerId: 'user1',
         supplierId: 'supplier1',
         totalAmount: 100.0,
         status: OrderStatus.pending,
         type: OrderType.product,
         createdAt: Timestamp.now(),
         updatedAt: Timestamp.now(),
       );
       when(mockFirebaseFirestore.collection('orders') as dynamic)
           .thenReturn(mockCollectionReference);
       when(mockCollectionReference.doc('order1'))
           .thenReturn(mockDocumentReference);
       when(mockDocumentReference.set(order.toMap()))
           .thenAnswer((_) async {});

       await databaseService.createOrder(order);

       verify(mockFirebaseFirestore.collection('orders')).called(1);
       verify(mockCollectionReference.doc('order1')).called(1);
       verify(mockDocumentReference.set(order.toMap())).called(1);
     });

     test('getOrder returns OrderModel from Firestore', () async {
       when(mockFirebaseFirestore.collection('orders') as dynamic)
           .thenReturn(mockCollectionReference);
       when(mockCollectionReference.doc('order1'))
           .thenReturn(mockDocumentReference);
       when(mockDocumentReference.get())
           .thenAnswer((_) async => mockDocumentSnapshot);
       when(mockDocumentSnapshot.exists).thenReturn(true);
       when(mockDocumentSnapshot.data()).thenReturn({
         'id': 'order1',
         'userId': 'user1',
         'totalAmount': 100.0,
         'status': 'pending',
         'type': 'product',
         'createdAt': Timestamp.now(),
         'updatedAt': Timestamp.now(),
       });

       final order = await databaseService.getOrder('order1');

       expect(order, isA<OrderModel>());
       expect(order!.id, 'order1');
       expect(order.buyerId, 'user1');
       expect(order.totalAmount, 100.0);
       expect(order.status, OrderStatus.pending);
       expect(order.type, OrderType.product);
     });
   });

   group('PaymentModel', () {
     test('createPayment creates a payment in Firestore', () async {
       final payment = PaymentModel(
         id: 'payment1',
         orderId: 'order1',
         userId: 'user1',
         amount: 50.0,
         method: PaymentMethod.mpesa,
         status: PaymentStatus.pending,
         createdAt: Timestamp.fromDate(DateTime.now()),
         updatedAt: Timestamp.fromDate(DateTime.now()),
       );
       when(mockFirebaseFirestore.collection('payments') as dynamic)
           .thenReturn(mockCollectionReference);
       when(mockCollectionReference.doc('payment1'))
           .thenReturn(mockDocumentReference);
       when(mockDocumentReference.set(payment.toMap()))
           .thenAnswer((_) async {});

       await databaseService.createPayment(payment);

       verify(mockFirebaseFirestore.collection('payments')).called(1);
       verify(mockCollectionReference.doc('payment1')).called(1);
       verify(mockDocumentReference.set(payment.toMap())).called(1);
     });

     test('getPayment returns PaymentModel from Firestore', () async {
       when(mockFirebaseFirestore.collection('payments') as dynamic)
           .thenReturn(mockCollectionReference);
       when(mockCollectionReference.doc('payment1'))
           .thenReturn(mockDocumentReference);
       when(mockDocumentReference.get())
           .thenAnswer((_) async => mockDocumentSnapshot);
       when(mockDocumentSnapshot.exists).thenReturn(true);
       when(mockDocumentSnapshot.data()).thenReturn({
         'id': 'payment1',
         'orderId': 'order1',
         'userId': 'user1',
         'amount': 50.0,
         'method': 'mpesa',
         'status': 'pending',
         'createdAt': Timestamp.now(),
         'updatedAt': Timestamp.now(),
       });

       final payment = await databaseService.getPayment('payment1');

       expect(payment, isA<PaymentModel>());
       expect(payment!.id, 'payment1');
       expect(payment.orderId, 'order1');
       expect(payment.userId, 'user1');
       expect(payment.amount, 50.0);
       expect(payment.method, PaymentMethod.mpesa);
       expect(payment.status, PaymentStatus.pending);
     });
   });

   group('FinancialTransactionModel', () {
     test('createFinancialTransaction creates a transaction in Firestore', () async {
       final transaction = FinancialTransaction(
         id: 'transaction1',
         relatedId: 'order1', // Added relatedId
         orderId: 'order1',
         userId: 'user1',
         amount: 10.0,
         type: TransactionType.commission,
         status: TransactionStatus.completed,
         createdAt: Timestamp.fromDate(DateTime.now()),
         updatedAt: Timestamp.fromDate(DateTime.now()),
       );
       when(mockFirebaseFirestore.collection('financialTransactions') as dynamic)
           .thenReturn(mockCollectionReference);
       when(mockCollectionReference.doc('transaction1'))
           .thenReturn(mockDocumentReference);
       when(mockDocumentReference.set(transaction.toMap()))
           .thenAnswer((_) async {});

       await databaseService.createFinancialTransaction(transaction);

       verify(mockFirebaseFirestore.collection('financialTransactions')).called(1);
       verify(mockCollectionReference.doc('transaction1')).called(1);
       verify(mockDocumentReference.set(transaction.toMap())).called(1);
     });

     test('getFinancialTransaction returns FinancialTransactionModel from Firestore', () async {
       when(mockFirebaseFirestore.collection('financialTransactions') as dynamic)
           .thenReturn(mockCollectionReference);
       when(mockCollectionReference.doc('transaction1'))
           .thenReturn(mockDocumentReference);
       when(mockDocumentReference.get())
           .thenAnswer((_) async => mockDocumentSnapshot);
       when(mockDocumentSnapshot.exists).thenReturn(true);
       when(mockDocumentSnapshot.data()).thenReturn({
         'id': 'transaction1',
         'orderId': 'order1',
         'userId': 'user1',
         'amount': 10.0,
         'type': 'commission',
         'status': 'completed',
         'createdAt': Timestamp.now(),
         'updatedAt': Timestamp.now(),
       });

       final transaction = await databaseService.getFinancialTransaction('transaction1');

       expect(transaction, isA<FinancialTransaction>());
       expect(transaction!.id, 'transaction1');
       expect(transaction.orderId, 'order1');
       expect(transaction.userId, 'user1');
       expect(transaction.amount, 10.0);
       expect(transaction.type, TransactionType.commission);
       expect(transaction.status, TransactionStatus.completed);
     });
   });

   group('MessageModel', () {
     test('createMessage creates a message in Firestore', () async {
       final message = MessageModel(
         receiverId: 'receiver1',
         id: 'message1',
         chatId: 'chat1',
         senderId: 'user1',
         content: 'Hello',
         type: MessageType.text,
         status: MessageStatus.sent,
         createdAt: Timestamp.fromDate(DateTime.now()),
         updatedAt: Timestamp.fromDate(DateTime.now()),
       );
       when(mockFirebaseFirestore.collection('messages') as dynamic)
           .thenReturn(mockCollectionReference);
       when(mockCollectionReference.doc('message1'))
           .thenReturn(mockDocumentReference);
       when(mockDocumentReference.set(message.toMap()))
           .thenAnswer((_) async {});

       await databaseService.createMessage(message);

       verify(mockFirebaseFirestore.collection('messages')).called(1);
       verify(mockCollectionReference.doc('message1')).called(1);
       verify(mockDocumentReference.set(message.toMap())).called(1);
     });

     test('getMessage returns MessageModel from Firestore', () async {
       when(mockFirebaseFirestore.collection('messages') as dynamic)
           .thenReturn(mockCollectionReference);
       when(mockCollectionReference.doc('message1'))
           .thenReturn(mockDocumentReference);
       when(mockDocumentReference.get())
           .thenAnswer((_) async => mockDocumentSnapshot);
       when(mockDocumentSnapshot.exists).thenReturn(true);
       when(mockDocumentSnapshot.data()).thenReturn({
         'id': 'message1',
         'chatId': 'chat1',
         'senderId': 'user1',
         'content': 'Hello',
         'type': 'text',
         'status': 'sent',
         'createdAt': Timestamp.now(),
         'updatedAt': Timestamp.now(),
       });

       final message = await databaseService.getMessage('message1');

       expect(message, isA<MessageModel>());
       expect(message!.id, 'message1');
       expect(message.chatId, 'chat1');
       expect(message.senderId, 'user1');
       expect(message.content, 'Hello');
       expect(message.type, MessageType.text);
       expect(message.status, MessageStatus.sent);
     });
    });
