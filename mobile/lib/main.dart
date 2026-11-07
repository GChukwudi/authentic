import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/app.dart';
import 'package:mobile/app/providers.dart';
import 'package:mobile/data/mock/mock_world.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // No backend yet: everything runs on a seeded in-memory world.
  final world = await MockWorld.create();

  runApp(
    ProviderScope(
      overrides: [mockWorldProvider.overrideWithValue(world)],
      child: const AuthenticApp(),
    ),
  );
}
