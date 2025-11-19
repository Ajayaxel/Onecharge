class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

