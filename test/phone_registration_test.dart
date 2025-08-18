import 'package:flutter_test/flutter_test.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';

void main() {
  group('Phone Registration Tests', () {
    test('UserModel can be created without email', () {
      final user = UserModel(
        uid: 'test123',
        firstName: 'Test',
        lastName: 'User',
        phoneNumber: '+255712345678',
        role: UserRole.engineer,
        isApproved: false,
      );

      expect(user.uid, 'test123');
      expect(user.displayName, 'Test User');
      expect(user.email, isNull);
      expect(user.phoneNumber, '+255712345678');
    });

    test('UserModel can be created with email', () {
      final user = UserModel(
        uid: 'test456',
        firstName: 'Test',
        lastName: 'User 2',
        email: 'test@example.com',
        phoneNumber: '+255712345679',
        role: UserRole.supplier,
        isApproved: true,
      );

      expect(user.uid, 'test456');
      expect(user.displayName, 'Test User 2');
      expect(user.email, 'test@example.com');
      expect(user.phoneNumber, '+255712345679');
    });

    test('UserModel toMap handles null email correctly', () {
      final user = UserModel(
        uid: 'test123',
        firstName: 'Test',
        lastName: 'User',
        phoneNumber: '+255712345678',
        role: UserRole.engineer,
        isApproved: false,
      );

      final map = user.toJson();
      expect(map['email'], isNull);
      expect(map['phoneNumber'], '+255712345678');
    });
  });
}
