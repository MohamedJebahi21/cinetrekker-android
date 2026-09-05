import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/environment.dart';

class FeedbackRepository {
  FeedbackRepository({Dio? client}) : _client = client ?? Dio();

  final Dio _client;

  Future<void> submit({
    required String name,
    required String email,
    required String message,
  }) async {
    final baseUrl = Environment.apiBaseUrl.trim().replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    if (baseUrl.isEmpty) {
      throw const FeedbackException('The feedback service is not configured.');
    }

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '$baseUrl/api/feedback',
        data: <String, dynamic>{
          'name': name.trim(),
          'email': email.trim(),
          'message': message.trim(),
          'website': '',
        },
        options: Options(
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return;
      }
      throw FeedbackException(_messageFromResponse(response.data));
    } on DioException catch (error) {
      final response = error.response;
      final message = response?.data is Map
          ? _messageFromResponse(
              (response!.data as Map).cast<String, dynamic>(),
            )
          : 'Unable to send feedback. Please try again later.';
      throw FeedbackException(message, cause: error);
    }
  }

  String _messageFromResponse(Map<String, dynamic>? data) {
    final message = data?['error'] ?? data?['detail'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Unable to send feedback. Please try again later.';
  }
}

class FeedbackException implements Exception {
  const FeedbackException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});
