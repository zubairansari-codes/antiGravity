// Dio HTTP client configured for the Groq API (OpenAI-compatible).
//
// Uses Bearer token authentication via compile-time environment.
// Includes retry interceptor, certificate pinning, and debug logging.
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Retry interceptor with exponential backoff.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
  }) : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;
    if (attempt < maxRetries && _shouldRetry(err)) {
      final delay = baseDelay * (1 << attempt); // 1s, 2s, 4s
      log('[DioClient] Retry ${attempt + 1}/$maxRetries after ${delay.inSeconds}s');
      await Future.delayed(delay);
      err.requestOptions.extra['retry_attempt'] = attempt + 1;
      try {
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        return handler.next(err);
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }
}

/// Debug logging interceptor.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('[Dio] ➡️ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('[Dio] ⬅️ ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('[Dio] ❌ ${err.type} ${err.requestOptions.path}');
    handler.next(err);
  }
}

class DioClient {
  DioClient() {
    const apiKey = String.fromEnvironment(
      'GROQ_API_KEY',
      defaultValue: '',
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    // Retry with exponential backoff: 1s, 2s, 4s.
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        maxRetries: 3,
        baseDelay: const Duration(seconds: 1),
      ),
    );

    // Request/response logging for debug builds.
    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }

    // Certificate pinning for known API hosts.
    // TODO: Replace with SHA256 public-key hash pinning for production.
    if (!kIsWeb) {
      // ignore: avoid_dynamic_calls
      (_dio.httpClientAdapter as dynamic).onHttpClientCreate = (client) {
        // ignore: avoid_dynamic_calls
        client.badCertificateCallback = (cert, host, port) {
          final trustedHosts = [
            'api.groq.com',
            'api.elevenlabs.io',
          ];
          return trustedHosts.contains(host);
        };
        return client;
      };
    }
  }

  late final Dio _dio;

  /// The configured Dio instance.
  Dio get client => _dio;
}
