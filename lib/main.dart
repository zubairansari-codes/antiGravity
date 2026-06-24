/// AntiGravity — main entry point.
///
/// Initialises: dotenv, Hive, and orientation lock.
/// Wraps the app in Riverpod's ProviderScope.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/home/data/models/brainstorm_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env must be in assets).
  await dotenv.load(fileName: '.env');

  // Initialise Hive for local storage.
  await Hive.initFlutter();
  Hive.registerAdapter(BrainstormModelAdapter());
  await Hive.openBox<BrainstormModel>('brainstorms');

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
