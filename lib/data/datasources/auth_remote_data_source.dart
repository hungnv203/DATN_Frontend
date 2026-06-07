import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(String email, String password, String fullName, String phoneNumber);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await client.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        return {
          'user': UserModel.fromJson(response.data['user']),
          'token': response.data['accessToken'],
        };
      } else {
        throw ServerException(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<Map<String, dynamic>> register(String email, String password, String fullName, String phoneNumber) async {
    try {
      final response = await client.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'user': UserModel.fromJson(response.data['user']),
          'token': response.data['accessToken'],
        };
      } else {
        throw ServerException(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? e.message);
    }
  }
}
