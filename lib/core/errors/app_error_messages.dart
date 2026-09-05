import 'package:dio/dio.dart';

String describeAppError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'We couldn’t reach CineTrekker. Check your connection and try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return 'Your session needs attention. Please sign in again.';
        }
        if (statusCode != null) {
          return 'CineTrekker is temporarily unavailable. Please try again shortly.';
        }
        return 'We couldn’t load that right now. Please try again.';
      case DioExceptionType.cancel:
        return 'That request was interrupted. Please try again.';
      case DioExceptionType.badCertificate:
        return 'We couldn’t establish a secure connection. Please try again.';
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return 'Unable to load data right now.';
    }
  }

  if (error is StateError) {
    return 'We couldn’t load that right now. Please try again.';
  }

  if (error is FormatException) {
    return 'We received an unexpected response. Please try again.';
  }

  return 'Something went wrong while loading data.';
}
