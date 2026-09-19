import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/core/error/exceptions.dart';
import 'package:movie_booking_app/core/utils/role_validator.dart';
import 'package:movie_booking_app/data/datasources/auth_remote_data_source.dart';
import 'package:movie_booking_app/data/models/user_model.dart';
import 'package:movie_booking_app/data/repositories/auth_repository_impl.dart';
import 'package:movie_booking_app/domain/usecases/login_usecase.dart';
import 'package:movie_booking_app/domain/usecases/logout_usecase.dart';
import 'package:movie_booking_app/domain/usecases/register_usecase.dart';
import 'package:movie_booking_app/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  Map<String, dynamic>? mockResponse;
  Exception? exceptionToThrow;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return mockResponse!;
  }

  @override
  Future<Map<String, dynamic>> register(
      String email, String password, String fullName, String phoneNumber) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return mockResponse!;
  }
}

String createTestJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final signature = base64Url.encode(utf8.encode('signature'));
  return '$header.$body.$signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoleValidator - Mobile App', () {
    test('allows only customer role case-insensitively', () {
      expect(RoleValidator.isAllowedMobileCustomerRole('Customer'), isTrue);
      expect(RoleValidator.isAllowedMobileCustomerRole('customer'), isTrue);
      expect(RoleValidator.isAllowedMobileCustomerRole('CUSTOMER'), isTrue);
    });

    test('strictly disallows admin, staff, and invalid roles', () {
      expect(RoleValidator.isAllowedMobileCustomerRole('Admin'), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole('admin'), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole('ADMIN'), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole('Staff'), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole('staff'), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole('STAFF'), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole(null), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole(''), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole('   '), isFalse);
      expect(RoleValidator.isAllowedMobileCustomerRole('Manager'), isFalse);
    });

    test('extractRoleFromJwt parses standard claim', () {
      final token = createTestJwt({'role': 'Customer'});
      expect(RoleValidator.extractRoleFromJwt(token), 'Customer');
    });

    test('extractRoleFromJwt parses .NET schema claim type', () {
      final token = createTestJwt({
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'Admin',
      });
      expect(RoleValidator.extractRoleFromJwt(token), 'Admin');
    });

    test('extractRoleFromJwt handles malformed token safely', () {
      expect(RoleValidator.extractRoleFromJwt('bad.token'), isNull);
      expect(RoleValidator.extractRoleFromJwt(null), isNull);
      expect(RoleValidator.extractRoleFromJwt(''), isNull);
    });
  });

  group('UserModel Role Parsing - Mobile App', () {
    test('parses roleName from backend response', () {
      final json = {
        'id': 'u100',
        'email': 'customer@test.com',
        'fullName': 'Customer Test',
        'phoneNumber': '0901234567',
        'roleName': 'Customer',
        'loyaltyPoints': 20,
      };
      final user = UserModel.fromJson(json);
      expect(user.role, 'Customer');
      expect(user.loyaltyPoints, 20);
    });

    test('falls back to JWT role if roleName missing in JSON', () {
      final json = {
        'id': 'u101',
        'email': 'customer2@test.com',
        'fullName': 'Customer 2',
        'phoneNumber': '0901234568',
      };
      final user = UserModel.fromJson(json, 'Customer');
      expect(user.role, 'Customer');
    });
  });

  group('AuthRepositoryImpl Role Enforcement - Mobile App', () {
    test('allows login for Customer role and stores token in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final remoteDataSource = MockAuthRemoteDataSource();
      remoteDataSource.mockResponse = {
        'user': const UserModel(
          id: 'u1',
          email: 'customer@test.com',
          fullName: 'Customer Test',
          phoneNumber: '0123456789',
          loyaltyPoints: 0,
          role: 'Customer',
        ),
        'token': 'valid-customer-token',
      };

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        prefs: prefs,
      );

      final user = await repository.login('customer@test.com', 'Pass123!');

      expect(user.role, 'Customer');
      expect(prefs.getString('auth_token'), 'valid-customer-token');
    });

    test('rejects login for Admin role with ServerException and does not save token', () async {
      final prefs = await SharedPreferences.getInstance();
      final remoteDataSource = MockAuthRemoteDataSource();
      remoteDataSource.mockResponse = {
        'user': const UserModel(
          id: 'u2',
          email: 'admin@cinema.com',
          fullName: 'Admin User',
          phoneNumber: '0123456789',
          loyaltyPoints: 0,
          role: 'Admin',
        ),
        'token': 'valid-admin-token',
      };

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        prefs: prefs,
      );

      await expectLater(
        () => repository.login('admin@cinema.com', 'AdminPass123!'),
        throwsA(isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Tài khoản quản trị không thể đăng nhập trên ứng dụng khách hàng.',
        )),
      );

      expect(prefs.getString('auth_token'), isNull);
    });

    test('rejects login for Staff role and clears existing token', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'pre-existing-token');

      final remoteDataSource = MockAuthRemoteDataSource();
      remoteDataSource.mockResponse = {
        'user': const UserModel(
          id: 'u3',
          email: 'staff@cinema.com',
          fullName: 'Staff User',
          phoneNumber: '0123456789',
          loyaltyPoints: 0,
          role: 'Staff',
        ),
        'token': 'new-staff-token',
      };

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        prefs: prefs,
      );

      await expectLater(
        () => repository.login('staff@cinema.com', 'StaffPass123!'),
        throwsA(isA<ServerException>()),
      );

      expect(prefs.getString('auth_token'), isNull);
    });
  });

  group('AuthProvider Login Role Enforcement - Mobile App', () {
    test('succeeds for Customer role', () async {
      final prefs = await SharedPreferences.getInstance();
      final remoteDataSource = MockAuthRemoteDataSource();
      remoteDataSource.mockResponse = {
        'user': const UserModel(
          id: 'u1',
          email: 'customer@test.com',
          fullName: 'Customer Test',
          phoneNumber: '0123456789',
          loyaltyPoints: 10,
          role: 'Customer',
        ),
        'token': 'customer-token',
      };

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        prefs: prefs,
      );
      final loginUseCase = LoginUseCase(repository);
      final registerUseCase = RegisterUseCase(repository);
      final logoutUseCase = LogoutUsecase(repository);

      final authProvider = AuthProvider(loginUseCase, registerUseCase, logoutUseCase);

      final success = await authProvider.login('customer@test.com', 'Pass123!');

      expect(success, isTrue);
      expect(authProvider.state, AuthState.success);
      expect(authProvider.currentUser?.role, 'Customer');
      expect(authProvider.errorMessage, isNull);
    });

    test('fails for Admin role with clear Vietnamese error message and clears user state', () async {
      final prefs = await SharedPreferences.getInstance();
      final remoteDataSource = MockAuthRemoteDataSource();
      remoteDataSource.mockResponse = {
        'user': const UserModel(
          id: 'u2',
          email: 'admin@cinema.com',
          fullName: 'Admin User',
          phoneNumber: '0123456789',
          loyaltyPoints: 0,
          role: 'Admin',
        ),
        'token': 'admin-token',
      };

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        prefs: prefs,
      );
      final loginUseCase = LoginUseCase(repository);
      final registerUseCase = RegisterUseCase(repository);
      final logoutUseCase = LogoutUsecase(repository);

      final authProvider = AuthProvider(loginUseCase, registerUseCase, logoutUseCase);

      final success = await authProvider.login('admin@cinema.com', 'AdminPass123!');

      expect(success, isFalse);
      expect(authProvider.state, AuthState.error);
      expect(authProvider.currentUser, isNull);
      expect(
        authProvider.errorMessage,
        'Tài khoản quản trị không thể đăng nhập trên ứng dụng khách hàng.',
      );
      expect(prefs.getString('auth_token'), isNull);
    });
  });
}
