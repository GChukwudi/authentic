import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/app/shell.dart';
import 'package:mobile/app/theme/app_theme.dart';

class AuthenticApp extends StatelessWidget {
  const AuthenticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: MaterialApp(
        title: 'Authentic',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AppShell(),
      ),
    );
  }
}
