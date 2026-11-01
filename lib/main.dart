import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/application/app_controller.dart';
import 'src/core/config.dart';
import 'src/data/api_repository.dart';
import 'src/data/demo_repository.dart';
import 'src/data/local_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const store = AndroidLocalStore();
  runApp(
    ChifaApp(
      controller: AppController(
        repository: AppConfig.useMock
            ? DemoRepository(store: store)
            : ApiRepository(baseUrl: AppConfig.apiBaseUrl),
        store: store,
        namespace: AppConfig.useMock ? 'demo' : 'api.${AppConfig.apiBaseUrl}',
      ),
    ),
  );
}
