import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/application/app_controller.dart';
import 'src/core/config.dart';
import 'src/data/api_repository.dart';
import 'src/data/demo_repository.dart';
import 'src/data/local_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const almacenamiento = AndroidLocalStore();
  runApp(
    ChifaApp(
      controlador: AppController(
        repositorio: AppConfig.usarDemo
            ? DemoRepository(almacenamiento: almacenamiento)
            : ApiRepository(urlBase: AppConfig.urlBaseApi),
        almacenamiento: almacenamiento,
        espacioDatos: AppConfig.usarDemo
            ? 'demo'
            : 'api.${AppConfig.urlBaseApi}',
      ),
    ),
  );
}
