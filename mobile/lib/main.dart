import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app/app.dart';
import 'package:mobile/app/app_config.dart';
import 'package:mobile/app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    runApp(const _MissingConfig());
    return;
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: const AuthenticApp(),
    ),
  );
}

/// Shown when the app was built without --dart-define=API_URL=...
class _MissingConfig extends StatelessWidget {
  const _MissingConfig();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'API_URL is not set.\nBuild with --dart-define=API_URL=<backend url>.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
