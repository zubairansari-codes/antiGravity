// AntiGravity — main entry point.
//
// Initialises: secure Hive storage, and orientation lock.
// Wraps the app in Riverpod's ProviderScope.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/home/data/models/brainstorm_model.dart';

const _secureStorage = FlutterSecureStorage();
const _hiveKeyName = 'hive_encryption_key';

Future<Uint8List> _getHiveEncryptionKey() async {
  final existing = await _secureStorage.read(key: _hiveKeyName);
  if (existing != null) {
    return base64Decode(existing);
  }
  // Generate a new 256-bit key.
  final key = Hive.generateSecureKey();
  await _secureStorage.write(key: _hiveKeyName, value: base64Encode(key));
  return Uint8List.fromList(key);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive for local storage with encryption.
  await Hive.initFlutter();
  Hive.registerAdapter(BrainstormModelAdapter());
  // TODO: Move BrainstormModelAdapter to a core location to avoid importing
  // from the data layer in main.dart.
  final encryptionKey = await _getHiveEncryptionKey();
  await Hive.openBox<BrainstormModel>(
    'brainstorms',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  // Lock to portrait orientation.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: AntiGravityApp()));
}
