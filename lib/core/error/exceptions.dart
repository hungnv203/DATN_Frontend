class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  ServerException(
      [this.message = 'Server Exception', this.statusCode, this.errorCode]);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache Exception']);

  @override
  String toString() => message;
}
