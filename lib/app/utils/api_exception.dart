/// Base class for all API related exceptions.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details; // For additional error details from API response

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    String result = 'ApiException: $message';
    if (statusCode != null) {
      result += ' (Status Code: $statusCode)';
    }
    if (details != null) {
      result += '\nDetails: $details';
    }
    return result;
  }
}

/// Exception for authentication failures (e.g., 401 Unauthorized, missing token).
class ApiAuthException extends ApiException {
  ApiAuthException(String message, {dynamic details})
    : super(message, statusCode: 401, details: details);
}

/// Exception for authorization failures (e.g., 403 Forbidden).
class ApiForbiddenException extends ApiException {
  ApiForbiddenException(String message, {dynamic details})
    : super(message, statusCode: 403, details: details);
}

/// Exception for validation errors from the API (e.g., 400 Bad Request, 422 Unprocessable Entity).
class ApiValidationException extends ApiException {
  final Map<String, dynamic>? errors; // Field-specific validation errors

  ApiValidationException(String message, {this.errors, dynamic details})
    : super(
        message,
        statusCode: 400,
        details: details,
      ); // Default to 400, can be 422

  @override
  String toString() {
    String result = super.toString();
    if (errors != null && errors!.isNotEmpty) {
      result += '\nValidation Errors: $errors';
    }
    return result;
  }
}

/// Exception for when a resource is not found (e.g., 404 Not Found).
class ApiNotFoundException extends ApiException {
  ApiNotFoundException(String message, {dynamic details})
    : super(message, statusCode: 404, details: details);
}

/// Exception for general server-side errors (e.g., 500 Internal Server Error).
class ApiServerException extends ApiException {
  ApiServerException(String message, {int? statusCode, dynamic details})
    : super(message, statusCode: statusCode ?? 500, details: details);
}

/// Exception for unexpected data format from the API.
class ApiDataParsingException extends ApiException {
  ApiDataParsingException(String message, {dynamic details})
    : super(message, details: details);
}

/// Exception for network or connectivity issues.
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
