/// Custom exceptions for JengaMate application
/// Provides structured error handling throughout the app

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Authentication related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Database related exceptions
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Validation related exceptions
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// File/Storage related exceptions
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Permission related exceptions
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Business logic exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Common exception factory methods
class AppExceptions {
  static AuthenticationException invalidCredentials() =>
    const AuthenticationException('Invalid email or password');

  static AuthenticationException userNotFound() =>
    const AuthenticationException('User not found');

  static AuthenticationException emailNotVerified() =>
    const AuthenticationException('Please verify your email before proceeding');

  static AuthenticationException sessionExpired() =>
    const AuthenticationException('Your session has expired. Please log in again');

  static NetworkException noInternet() =>
    const NetworkException('No internet connection. Please check your network and try again');

  static NetworkException serverError() =>
    const NetworkException('Server error. Please try again later');

  static NetworkException timeout() =>
    const NetworkException('Request timeout. Please try again');

  static DatabaseException dataNotFound() =>
    const DatabaseException('Requested data not found');

  static DatabaseException duplicateEntry() =>
    const DatabaseException('This entry already exists');

  static StorageException uploadFailed() =>
    const StorageException('File upload failed. Please try again');

  static StorageException downloadFailed() =>
    const StorageException('File download failed. Please try again');

  static PermissionException accessDenied() =>
    const PermissionException('You do not have permission to perform this action');

  static BusinessLogicException invalidOperation() =>
    const BusinessLogicException('This operation is not allowed in the current state');

  static ValidationException requiredField(String fieldName) =>
    ValidationException(
      'The $fieldName field is required',
      fieldErrors: {fieldName: 'This field is required'},
    );

  static ValidationException invalidEmail() =>
    const ValidationException(
      'Please enter a valid email address',
      fieldErrors: {'email': 'Invalid email format'},
    );

  static ValidationException weakPassword() =>
    const ValidationException(
      'Password must be at least 8 characters long and contain uppercase, lowercase, and numbers',
      fieldErrors: {'password': 'Password does not meet requirements'},
    );
}
