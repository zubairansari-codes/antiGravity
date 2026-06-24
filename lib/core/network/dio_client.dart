/// Dio HTTP client configured for the Groq API (OpenAI-compatible).
///
/// Uses Bearer token authentication.
/// API key is loaded from `.env` via flutter_dotenv.
library;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/app_constants.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

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
  }

  /// The configured Dio instance.
  Dio get client => _dio;
}
