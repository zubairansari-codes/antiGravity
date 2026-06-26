// Network connectivity checker.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final dynamic result = await _connectivity.checkConnectivity();
    // Handle both single result (v5) and list result (v6+) APIs.
    if (result is List<ConnectivityResult>) {
      return result.isNotEmpty && !result.contains(ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }
}

/// Exported provider so repositories and use cases can inject connectivity.
final coreNetworkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(Connectivity()),
);
