import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/role_validator.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences prefs;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.prefs,
  });

  @override
  Future<User> login(String email, String password) async {
    final response = await remoteDataSource.login(email, password);
    final userModel = response['user'] as UserModel;
    final token = response['token'] as String?;

    if (!RoleValidator.isAllowedMobileCustomerRole(userModel.role)) {
      await logout();
      throw ServerException('Tài khoản quản trị không thể đăng nhập trên ứng dụng khách hàng.');
    }

    if (token != null) {
      await prefs.setString('auth_token', token);
    }

    return userModel;
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    final response = await remoteDataSource.register(email, password, fullName, phoneNumber);
    final userModel = response['user'] as UserModel;
    final token = response['token'] as String?;

    if (!RoleValidator.isAllowedMobileCustomerRole(userModel.role)) {
      await logout();
      throw ServerException('Tài khoản quản trị không thể đăng nhập trên ứng dụng khách hàng.');
    }

    if (token != null) {
      await prefs.setString('auth_token', token);
    }

    return userModel;
  }

  @override
  Future<void> logout() async {
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = prefs.getString('auth_token');
    if (token != null) {
      final role = RoleValidator.extractRoleFromJwt(token);
      if (!RoleValidator.isAllowedMobileCustomerRole(role)) {
        await logout();
        return null;
      }
    }
    return null;
  }
}

