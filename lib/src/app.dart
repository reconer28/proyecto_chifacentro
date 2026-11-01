import 'package:flutter/material.dart';

import 'application/app_controller.dart';
import 'core/theme.dart';
import 'presentation/login_screen.dart';
import 'presentation/shell.dart';

class ChifaApp extends StatelessWidget {
  const ChifaApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chifa Centro',
    debugShowCheckedModeBanner: false,
    theme: chifaTheme(),
    home: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => controller.user == null
          ? LoginScreen(controller: controller)
          : AppShell(controller: controller),
    ),
  );
}
