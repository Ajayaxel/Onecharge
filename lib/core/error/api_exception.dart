class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;
  final String? email;

  ApiException(this.message, {this.statusCode, this.errors, this.email});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

