import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/models/notification_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:mockito/mockito.dart';

import '../mocks/firebase_mocks.mocks.dart';

void main() {
  // Mocks
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
  late MockCollectionReference<Map<String, dynamic>>
      mockNotificationsCollection;
  late MockDocumentReference<Map<String, dynamic>> mockUserDocument;
  late MockDocumentReference<Map<String, dynamic>> mockNotificationDocument;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
  late MockQuery<Map<String, dynamic>> mockQuery;

  // Class under test
  late DatabaseService databaseService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference<Map<String, dynamic>>();
    mockNotificationsCollection =
        MockCollectionReference<Map<String, dynamic>>();
    mockUserDocument = MockDocumentReference<Map<String, dynamic>>();
    mockNotificationDocument = MockDocumentReference<Map<String, dynamic>>();
    mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    mockQuery = MockQuery<Map<String, dynamic>>();

    databaseService = DatabaseService();

    // Default mock behavior
    when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
    when(mockUsersCollection.doc(any)).thenReturn(mockUserDocument);
    when(mockFirestore.collection('notifications'))
        .thenReturn(mockNotificationsCollection);
    when(mockNotificationsCollection.doc(any))
        .thenReturn(mockNotificationDocument);
    when(mockNotificationsCollection.where(any,
            isEqualTo: anyNamed('isEqualTo')))
        .thenReturn(mockQuery);
    when(mockQuery.orderBy(any, descending: anyNamed('descending')))
        .thenReturn(mockQuery);
  });

  group('DatabaseService Tests', () {
    const testUserId = 'test-user-id';
    final testUser = UserModel(
      uid: testUserId,
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
    );

    group('getUser', () {
      test('should return UserModel when user exists', () async {
        // Arrange
        final mockData = testUser.toMap();
        when(mockUserDocument.get())
            .thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(mockData);
        when(mockDocumentSnapshot.id).thenReturn(testUserId);

        // Act
        final result = await databaseService.getUser(testUserId);

        // Assert
        expect(result, isA<UserModel>());
        expect(result?.uid, testUserId);
        expect(result?.email, testUser.email);
        verify(mockUsersCollection.doc(testUserId)).called(1);
      });

      test('should return null when user does not exist', () async {
        // Arrange
        when(mockUserDocument.get())
            .thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final result = await databaseService.getUser(testUserId);

        // Assert
        expect(result, isNull);
        verify(mockUsersCollection.doc(testUserId)).called(1);
      });

      test('should return null on Firestore exception', () async {
        // Arrange
        when(mockUserDocument.get())
            .thenThrow(FirebaseException(plugin: 'firestore'));

        // Act
        final result = await databaseService.getUser(testUserId);

        // Assert
        expect(result, isNull);
      });
    });

    group('createUser', () {
      test('should complete successfully when user is created', () async {
        // Arrange
        when(mockUserDocument.set(any)).thenAnswer((_) async => Future.value());

        // Act
        await databaseService.createUser(testUser);

        // Assert
        verify(mockUsersCollection.doc(testUser.uid)).called(1);
        verify(mockUserDocument.set(testUser.toMap())).called(1);
      });

      test('should throw exception on failure', () async {
        // Arrange
        final exception = FirebaseException(plugin: 'firestore');
        when(mockUserDocument.set(any)).thenThrow(exception);

        // Act & Assert
        expect(() => databaseService.createUser(testUser),
            throwsA(isA<FirebaseException>()));
      });
    });

    group('updateUser', () {
      test('should complete successfully when user is updated', () async {
        // Arrange
        when(mockUserDocument.update(any))
            .thenAnswer((_) async => Future.value());

        // Act
        await databaseService.updateUser(testUser);

        // Assert
        verify(mockUsersCollection.doc(testUser.uid)).called(1);
        verify(mockUserDocument.update(testUser.toMap())).called(1);
      });

      test('should throw exception on failure', () async {
        // Arrange
        final exception = FirebaseException(plugin: 'firestore');
        when(mockUserDocument.update(any)).thenThrow(exception);

        // Act & Assert
        expect(() => databaseService.updateUser(testUser),
            throwsA(isA<FirebaseException>()));
      });
    });

    group('createNotification', () {
      final testNotification = NotificationModel(
        id: 'test-notification-id',
        userId: testUserId,
        title: 'Test Notification',
        message: 'This is a test.',
        type: 'test',
        createdAt: DateTime.now(),
        timestamp: DateTime.now(),
      );

      test('should complete successfully when notification is created',
          () async {
        // Arrange
        when(mockNotificationDocument.set(any))
            .thenAnswer((_) async => Future.value());

        // Act
        await databaseService.createNotification(testNotification);

        // Assert
        verify(mockNotificationsCollection.doc(testNotification.id)).called(1);
        verify(mockNotificationDocument.set(testNotification.toMap()))
            .called(1);
      });

      test('should throw exception on failure', () async {
        // Arrange
        final exception = FirebaseException(plugin: 'firestore');
        when(mockNotificationDocument.set(any)).thenThrow(exception);

        // Act & Assert
        expect(() => databaseService.createNotification(testNotification),
            throwsA(isA<Exception>()));
      });
    });

    group('streamUserNotifications', () {
      test('should return a stream of notifications for a user', () {
        // Arrange
        final notification = NotificationModel(
          id: 'notif1',
          userId: testUserId,
          title: 'Title',
          message: 'Message',
          type: 'test',
          createdAt: DateTime.now(),
          timestamp: DateTime.now(),
        );
        final mockNotificationDocSnapshot =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockNotificationDocSnapshot.data())
            .thenReturn(notification.toMap());
        when(mockNotificationDocSnapshot.id).thenReturn(notification.id);

        final streamController =
            StreamController<QuerySnapshot<Map<String, dynamic>>>();
        when(mockQuery.snapshots()).thenAnswer((_) => streamController.stream);

        // Act
        final stream = databaseService.streamUserNotifications(testUserId);

        // Assert
        expect(stream, isA<Stream<List<NotificationModel>>>());
        stream.listen(expectAsync1((notifications) {
          expect(notifications.length, 1);
          expect(notifications.first.id, notification.id);
        }));

        // Simulate a Firestore update
        when(mockQuerySnapshot.docs).thenReturn([mockNotificationDocSnapshot]);
        streamController.add(mockQuerySnapshot);
        streamController.close();
      });
    });
  });
}
