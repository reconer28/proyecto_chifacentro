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
  testWidgets('Capturas de las pantallas principales', (probador) async {
    await probador.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => probador.binding.setSurfaceSize(null));
    final configuracion = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    ) as Map;
    final paquetes = configuracion['packages'] as List;
    final raiz = Uri.parse(
      '${(paquetes.firstWhere((paqueteActual) => paqueteActual['name'] == 'flutter') as Map)['rootUri']}/',
    );
    final fuentes = raiz.resolve('../../bin/cache/artifacts/material_fonts/');
    for (final entradaFuente in {
      'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf', 'roboto-black.ttf'],
      'MaterialIcons': ['materialicons-regular.otf'],
    }.entries) {
      final cargador = FontLoader(entradaFuente.key);
      for (final archivo in entradaFuente.value) {
        cargador.addFont(
          Future.value(
            ByteData.sublistView(
              File.fromUri(fuentes.resolve(archivo)).readAsBytesSync(),
            ),
          ),
        );
      }
      await cargador.load();
    }
    final almacenamiento = MemoryStore();
    final estadoAplicacion = AppController(
      repositorio: DemoRepository(
        almacenamiento: almacenamiento,
        demora: Duration.zero,
      ),
      almacenamiento: almacenamiento,
    );
    addTearDown(estadoAplicacion.dispose);
    const clave = ValueKey('capture');
    Future<void> capturar(String nombre) async {
      await probador.pumpAndSettle();
      final limite = probador.renderObject<RenderRepaintBoundary>(
        find.byKey(clave),
      );
      await probador.runAsync(() async {
        final imagen = await limite.toImage(pixelRatio: 2);
        final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/previews').create(recursive: true);
        await File('build/previews/$nombre.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        imagen.dispose();
      });
      expect(probador.takeException(), isNull);
    }

    await probador.pumpWidget(
      RepaintBoundary(
        key: clave,
        child: ChifaApp(controlador: estadoAplicacion),
      ),
    );
    await capturar('01_login');
    await estadoAplicacion.iniciarSesion('mozo', '123456');
    await estadoAplicacion.modificarDetalle(
      '2',
      estadoAplicacion.productos[1],
      variacion: 2,
    );
    await estadoAplicacion.enviarPedido('2');
    await estadoAplicacion.modificarDetalle(
      '1',
      estadoAplicacion.productos[0],
      variacion: 2,
      observaciones: 'Sin cebolla, por favor',
    );
    await estadoAplicacion.modificarDetalle(
      '1',
      estadoAplicacion.productos[6],
      variacion: 1,
    );
    await capturar('02_mesas');
    await probador.ensureVisible(find.text('Mesa 01'));
    await probador.tap(find.text('Mesa 01'));
    await probador.pumpAndSettle();
    await capturar('03_carta');
    await probador.tap(find.text('Ver mi pedido'));
    await probador.pumpAndSettle();
    await capturar('04_pedido');
    await probador.pageBack();
    await probador.pumpAndSettle();
    await probador.tap(find.text('Cuenta de mesa'));
    await probador.pumpAndSettle();
    await probador.pageBack();
    await probador.pumpAndSettle();
    await probador.tap(find.text('Asignar'));
    await probador.pumpAndSettle();
    await capturar('05_asignacion');
    await probador.pageBack();
    await probador.pumpAndSettle();
    await probador.tap(find.text('Pedidos').last);
    await probador.pumpAndSettle();
    await capturar('06_pedidos');
    await probador.tap(find.text('Mi cuenta'));
    await probador.pumpAndSettle();
    await capturar('07_cuenta');
  }, skip: !const bool.fromEnvironment('CAPTURE_UI'));
}
