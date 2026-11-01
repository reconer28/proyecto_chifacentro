import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_chifacentro/src/app.dart';
import 'package:proyecto_chifacentro/src/application/app_controller.dart';
import 'package:proyecto_chifacentro/src/data/demo_repository.dart';
import 'package:proyecto_chifacentro/src/data/local_store.dart';

void main() {
  testWidgets('Capturas de las pantallas principales', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    ) as Map;
    final packages = config['packages'] as List;
    final root = Uri.parse(
      '${(packages.firstWhere((p) => p['name'] == 'flutter') as Map)['rootUri']}/',
    );
    final fonts = root.resolve('../../bin/cache/artifacts/material_fonts/');
    for (final entry in {
      'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf', 'roboto-black.ttf'],
      'MaterialIcons': ['materialicons-regular.otf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              File.fromUri(fonts.resolve(file)).readAsBytesSync(),
            ),
          ),
        );
      }
      await loader.load();
    }
    final store = MemoryStore();
    final c = AppController(
      repository: DemoRepository(store: store, delay: Duration.zero),
      store: store,
    );
    addTearDown(c.dispose);
    const key = ValueKey('capture');
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/previews').create(recursive: true);
        await File('build/previews/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ChifaApp(controller: c),
      ),
    );
    await capture('01_login');
    await c.login('mozo', '123456');
    await c.changeLine('2', c.products[1], delta: 2);
    await c.sendOrder('2');
    await c.changeLine(
      '1',
      c.products[0],
      delta: 2,
      notes: 'Sin cebolla, por favor',
    );
    await c.changeLine('1', c.products[6], delta: 1);
    await capture('02_mesas');
    await tester.ensureVisible(find.text('Mesa 01'));
    await tester.tap(find.text('Mesa 01'));
    await tester.pumpAndSettle();
    await capture('03_carta');
    await tester.tap(find.text('Ver mi pedido'));
    await tester.pumpAndSettle();
    await capture('04_pedido');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuenta de mesa'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar'));
    await tester.pumpAndSettle();
    await capture('05_asignacion');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedidos').last);
    await tester.pumpAndSettle();
    await capture('06_pedidos');
    await tester.tap(find.text('Mi cuenta'));
    await tester.pumpAndSettle();
    await capture('07_cuenta');
  }, skip: !const bool.fromEnvironment('CAPTURE_UI'));
}
