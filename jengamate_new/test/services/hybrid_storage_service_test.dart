import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/services/hybrid_storage_service.dart';
import 'package:jengamate/services/storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'hybrid_storage_service_test.mocks.dart';

@GenerateMocks([SupabaseClient, SupabaseStorageClient, StorageFileApi, StorageService])
void main() {
  late HybridStorageService hybridStorageService;
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseStorageClient mockSupabaseStorageClient;
  late MockStorageFileApi mockStorageFileApi;
  late MockStorageService mockFirebaseStorageService;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockSupabaseStorageClient = MockSupabaseStorageClient();
    mockStorageFileApi = MockStorageFileApi();
    mockFirebaseStorageService = MockStorageService();

    when(mockSupabaseClient.storage).thenReturn(mockSupabaseStorageClient);
    when(mockSupabaseStorageClient.from(any)).thenReturn(mockStorageFileApi);

    hybridStorageService = HybridStorageService(
      supabaseClient: mockSupabaseClient,
      firebaseStorageService: mockFirebaseStorageService,
    );
  });

  final testBytes = Uint8List.fromList([1, 2, 3]);
  const testFileName = 'test_image.jpg';
  const testFolder = 'test_folder';
  const supabaseUrl = 'https://test.supabase.co/storage/v1/object/public/test_folder/test_image.jpg';
  const firebaseUrl = 'https://firebasestorage.googleapis.com/v0/b/test.appspot.com/o/test_folder%2Ftest_image.jpg';

  group('HybridStorageService Tests', () {
    test('should upload to Supabase successfully', () async {
      // Arrange
      when(mockStorageFileApi.uploadBinary(any, any)).thenAnswer((_) async => '');
      when(mockStorageFileApi.getPublicUrl(any)).thenReturn(supabaseUrl);

      // Act
      final result = await hybridStorageService.uploadImage(
        fileName: testFileName,
        folder: testFolder,
        bytes: testBytes,
      );

      // Assert
      expect(result, supabaseUrl);
      verify(mockStorageFileApi.uploadBinary(any, any)).called(1);
      verifyNever(mockFirebaseStorageService.uploadImage(fileName: anyNamed('fileName'), folder: anyNamed('folder'), bytes: anyNamed('bytes')));
    });

    test('should fall back to Firebase when Supabase upload fails', () async {
      // Arrange
      when(mockStorageFileApi.uploadBinary(any, any)).thenThrow(Exception('Supabase error'));
      when(mockFirebaseStorageService.uploadImage(fileName: anyNamed('fileName'), folder: anyNamed('folder'), bytes: anyNamed('bytes'))).thenAnswer((_) async => firebaseUrl);

      // Act
      final result = await hybridStorageService.uploadImage(
        fileName: testFileName,
        folder: testFolder,
        bytes: testBytes,
      );

      // Assert
      expect(result, firebaseUrl);
      verify(mockStorageFileApi.uploadBinary(any, any)).called(1);
      verify(mockFirebaseStorageService.uploadImage(fileName: testFileName, folder: testFolder, bytes: testBytes)).called(1);
    });

    test('should return null when both Supabase and Firebase fail', () async {
      // Arrange
      when(mockStorageFileApi.uploadBinary(any, any)).thenThrow(Exception('Supabase error'));
      when(mockFirebaseStorageService.uploadImage(fileName: anyNamed('fileName'), folder: anyNamed('folder'), bytes: anyNamed('bytes'))).thenThrow(Exception('Firebase error'));

      // Act
      final result = await hybridStorageService.uploadImage(
        fileName: testFileName,
        folder: testFolder,
        bytes: testBytes,
      );

      // Assert
      expect(result, isNull);
    });

    test('should delete from Supabase successfully', () async {
      // Arrange
      when(mockStorageFileApi.remove(any)).thenAnswer((_) async => []);

      // Act
      final result = await hybridStorageService.deleteImage(supabaseUrl);

      // Assert
      expect(result, isTrue);
      verify(mockStorageFileApi.remove(['test_folder/test_image.jpg'])).called(1);
      verifyNever(mockFirebaseStorageService.deleteImage(any));
    });

    test('should delete from Firebase successfully', () async {
      // Arrange
      when(mockFirebaseStorageService.deleteImage(any)).thenAnswer((_) async => true);

      // Act
      final result = await hybridStorageService.deleteImage(firebaseUrl);

      // Assert
      expect(result, isTrue);
      verify(mockFirebaseStorageService.deleteImage(firebaseUrl)).called(1);
      verifyNever(mockStorageFileApi.remove(any));
    });
  });
}
