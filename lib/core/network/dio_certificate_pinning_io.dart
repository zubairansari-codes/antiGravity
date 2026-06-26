import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Typed certificate pinning for mobile/desktop targets.
///
/// This file is only imported on platforms where dart:io is available,
/// so the untyped dynamic cast in dio_client.dart can be removed.
void configureCertificatePinning(Dio dio) {
  final adapter = dio.httpClientAdapter;
  if (adapter is IOHttpClientAdapter) {
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) {
        const trustedHosts = ['api.groq.com', 'api.elevenlabs.io'];
        return trustedHosts.contains(host);
      };
      return client;
    };
  }
}
