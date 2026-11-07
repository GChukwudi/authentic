import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app/app.dart';
import 'package:mobile/app/app_config.dart';
import 'package:mobile/app/providers.dart';
import 'package:mobile/data/mock/mock_world.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // With --dart-define=API_URL=... the app talks to the backend. Without it,
  // everything runs on a seeded in-memory world.
  final overrides = AppConfig.isLive
      ? [
          preferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ]
      : [mockWorldProvider.overrideWithValue(await MockWorld.create())];

  runApp(
    ProviderScope(
      overrides: overrides,
      child: const AuthenticApp(),
    ),
  );
}
