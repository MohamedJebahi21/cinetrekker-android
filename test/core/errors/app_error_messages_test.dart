import 'package:cinetrekker_android/core/errors/app_error_messages.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final requestOptions = RequestOptions(path: '/titles');

  group('describeAppError', () {
    test('uses a recoverable message for connection failures', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
      );

      expect(
        describeAppError(error),
        'We couldn’t reach CineTrekker. Check your connection and try again.',
      );
    });

    test('does not expose credentials for authentication failures', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        describeAppError(error),
        'Your session needs attention. Please sign in again.',
      );
    });

    test('does not expose raw state or format exceptions', () {
      expect(
        describeAppError(StateError('internal connection string')),
        'We couldn’t load that right now. Please try again.',
      );
      expect(
        describeAppError(const FormatException('raw parser detail')),
        'We received an unexpected response. Please try again.',
      );
    });
  });
}
