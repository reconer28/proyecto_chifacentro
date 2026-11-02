import 'package:flutter/material.dart';

import 'application/app_controller.dart';
import 'core/theme.dart';
import 'presentation/login_screen.dart';
import 'presentation/shell.dart';

class ChifaApp extends StatelessWidget {
  const ChifaApp({super.key, required this.controlador});
  final AppController controlador;
  @override
  Widget build(BuildContext contexto) => MaterialApp(
    title: 'Chifa Centro',
    debugShowCheckedModeBanner: false,
    theme: crearTemaChifa(),
    home: AnimatedBuilder(
      animation: controlador,
      builder: (contexto, _) => controlador.usuario == null
          ? LoginScreen(controlador: controlador)
          : AppShell(controlador: controlador),
    ),
  );
}
