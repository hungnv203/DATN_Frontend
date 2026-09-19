import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final SharedPreferences _prefs;

  DioClient(SharedPreferences preferences) : _prefs = preferences {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle global errors here if needed
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        uri,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _toServerException(e);
    }
  }

  Future<Response> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _toServerException(e);
    }
  }

  Future<Response> put(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _toServerException(e);
    }
  }

  Future<Response> delete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _toServerException(e);
    }
  }

  ServerException _toServerException(DioException error) => ServerException(
        _handleDioError(error),
        error.response?.statusCode,
        _extractErrorCode(error),
      );

  String? _extractErrorCode(DioException error) {
    final data = error.response?.data;
    return data is Map && data['errorCode'] != null
        ? data['errorCode'].toString()
        : null;
  }

  String _handleDioError(DioException e) {
    if (e.response?.data != null) {
      try {
        final data = e.response!.data;
        if (data is Map) {
          if (data['message'] != null) {
            return data['message'].toString();
          }
          if (data['title'] != null) {
            String msg = data['title'].toString();
            if (data['errors'] != null && data['errors'] is Map) {
              final errors = data['errors'] as Map;
              if (errors.isNotEmpty) {
                final firstError = errors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  msg += ': ${firstError.first}';
                } else {
                  msg += ': $firstError';
                }
              }
            }
            return msg;
          }
          return data.toString();
        }
        return data.toString();
      } catch (_) {
        // Fallback to default behavior if parsing fails
      }
    }
    return e.message ?? 'Lỗi không xác định. Vui lòng thử lại.';
  }
}
