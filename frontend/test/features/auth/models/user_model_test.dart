import 'package:flutter_test/flutter_test.dart';
import 'package:kyrgyz_explore/features/auth/models/auth_models.dart';

void main() {
  // A typical JSON response from GET /users/me or POST /auth/login
  const jsonFull = {
    'id': 'abc-123',
    'email': 'aizat@example.com',
    'firstName': 'Aizat',
    'lastName': 'Bekova',
    'role': 'TRAVELER',
    'phone': '+996700000000',
    'profileImageUrl': 'https://s3.amazonaws.com/avatars/abc.jpg',
  };

  const jsonMinimal = {
    'id': 'xyz-999',
    'email': 'host@example.com',
    'firstName': 'Bakyt',
    'lastName': 'Umarov',
    'role': 'HOST',
  };

  group('UserModel.fromJson', () {
    test('parses all fields when present', () {
      final user = UserModel.fromJson(jsonFull);

      expect(user.id, 'abc-123');
      expect(user.email, 'aizat@example.com');
      expect(user.firstName, 'Aizat');
      expect(user.lastName, 'Bekova');
      expect(user.role, 'TRAVELER');
      expect(user.phone, '+996700000000');
      expect(user.profileImageUrl,
          'https://s3.amazonaws.com/avatars/abc.jpg');
    });

    test('parses without optional fields', () {
      final user = UserModel.fromJson(jsonMinimal);

      expect(user.phone, isNull);
      expect(user.profileImageUrl, isNull);
    });
  });

  group('UserModel computed properties', () {
    test('fullName concatenates first and last name', () {
      final user = UserModel.fromJson(jsonFull);
      expect(user.fullName, 'Aizat Bekova');
    });

    test('isHost is false for TRAVELER role', () {
      final user = UserModel.fromJson(jsonFull);
      expect(user.isHost, isFalse);
    });

    test('isHost is true for HOST role', () {
      final user = UserModel.fromJson(jsonMinimal);
      expect(user.isHost, isTrue);
    });
  });

  group('UserModel.copyWith', () {
    test('overrides only specified fields', () {
      final original = UserModel.fromJson(jsonFull);
      final updated = original.copyWith(firstName: 'Nuriza', phone: '+996555000000');

      expect(updated.firstName, 'Nuriza');
      expect(updated.phone, '+996555000000');
      // Unchanged fields stay the same
      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.lastName, original.lastName);
      expect(updated.role, original.role);
      expect(updated.profileImageUrl, original.profileImageUrl);
    });

    test('leaves all fields unchanged when no arguments given', () {
      final original = UserModel.fromJson(jsonFull);
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.firstName, original.firstName);
      expect(copy.lastName, original.lastName);
      expect(copy.phone, original.phone);
    });
  });
}
