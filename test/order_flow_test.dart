import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_chifacentro/src/application/app_controller.dart';
import 'package:proyecto_chifacentro/src/data/demo_repository.dart';
import 'package:proyecto_chifacentro/src/data/local_store.dart';
import 'package:proyecto_chifacentro/src/domain/models.dart';

class LostResponseRepository extends DemoRepository {
  LostResponseRepository({required super.almacenamiento})
    : super(demora: Duration.zero);
  bool perderSiguienteRespuesta = true;
  @override
  Future<ServiceOrder> enviarPedido(OrderDraft borrador) async {
    final pedido = await super.enviarPedido(borrador);
    if (perderSiguienteRespuesta) {
      perderSiguienteRespuesta = false;
      throw const AppException('Se perdió la respuesta después de guardar.');
    }
    return pedido;
  }
}

class AlmacenamientoConFallos extends MemoryStore {
  bool fallarLectura = false;
  String? claveFalloEscritura;

  @override
  Future<String?> leer(String clave) async {
    if (fallarLectura) {
      throw StateError('Lectura no disponible');
    }
    return super.leer(clave);
  }

  @override
  Future<void> guardar(String clave, String valor) async {
    if (clave == claveFalloEscritura) {
      throw StateError('Almacenamiento lleno');
    }
    await super.guardar(clave, valor);
  }
}

class RepositorioConSesionVencida extends LostResponseRepository {
  RepositorioConSesionVencida({required super.almacenamiento});
  int intentos = 0;

  @override
  Future<ServiceOrder> enviarPedido(OrderDraft borrador) async {
    if (++intentos == 2) {
      throw const AppException(
        'Sesión vencida',
        sesionVencida: true,
        rechazoDefinitivo: true,
      );
    }
    return super.enviarPedido(borrador);
  }
}

void main() {
  test(
    'Recupera los borradores tras un fallo de lectura sin sobrescribirlos',
    () async {
      final almacenamiento = AlmacenamientoConFallos();
      final controlador = AppController(
        repositorio: DemoRepository(
          almacenamiento: almacenamiento,
          demora: Duration.zero,
        ),
        almacenamiento: almacenamiento,
      );
      addTearDown(controlador.dispose);
      await controlador.iniciarSesion('mozo', '123456');
      await controlador.modificarDetalle(
        '1',
        controlador.productos.first,
        variacion: 2,
        observaciones: 'Sin cebolla',
      );
      await controlador.cerrarSesion();
      final guardado = almacenamiento.valores['drafts.v1.demo.1'];
      almacenamiento.fallarLectura = true;
      await controlador.iniciarSesion('mozo', '123456');
      expect(controlador.error, isNotNull);
      await controlador.cerrarSesion();
      expect(controlador.usuario, isNotNull);
      expect(almacenamiento.valores['drafts.v1.demo.1'], guardado);
      almacenamiento.fallarLectura = false;
      expect(await controlador.actualizarDatos(), isTrue);
      expect(controlador.borradorDeMesa('1')!.cantidad, 2);
      expect(
        controlador.borradorDeMesa('1')!.detalles.single.observaciones,
        'Sin cebolla',
      );
    },
  );

  test(
    'Valida cantidades y observaciones sin crear borradores vacíos',
    () async {
      final almacenamiento = MemoryStore();
      final controlador = AppController(
        repositorio: DemoRepository(
          almacenamiento: almacenamiento,
          demora: Duration.zero,
        ),
        almacenamiento: almacenamiento,
      );
      addTearDown(controlador.dispose);
      await controlador.iniciarSesion('mozo', '123456');
      expect(
        await controlador.modificarDetalle(
          '1',
          controlador.productos.first,
          variacion: 100,
        ),
        isFalse,
      );
      expect(controlador.borradores, isEmpty);
      expect(
        await controlador.modificarDetalle(
          '1',
          controlador.productos.last,
          variacion: 1,
        ),
        isFalse,
      );
      expect(controlador.borradores, isEmpty);
      await controlador.modificarDetalle(
        '1',
        controlador.productos.first,
        variacion: 0,
      );
      expect(controlador.borradores, isEmpty);
      await controlador.modificarDetalle(
        '1',
        controlador.productos.first,
        variacion: 99,
      );
      expect(
        await controlador.modificarDetalle(
          '1',
          controlador.productos.first,
          variacion: 1,
        ),
        isFalse,
      );
      expect(
        await controlador.modificarDetalle(
          '1',
          controlador.productos.first,
          observaciones: 'a' * 251,
        ),
        isFalse,
      );
      expect(controlador.borradorDeMesa('1')!.cantidad, 99);
      expect(
        controlador.borradorDeMesa('1')!.detalles.single.observaciones,
        isEmpty,
      );
    },
  );

  test(
    'No envía ni bloquea un pedido nuevo si no puede guardar su intención',
    () async {
      final almacenamiento = AlmacenamientoConFallos();
      final repositorio = DemoRepository(
        almacenamiento: almacenamiento,
        demora: Duration.zero,
      );
      final controlador = AppController(
        repositorio: repositorio,
        almacenamiento: almacenamiento,
      );
      addTearDown(controlador.dispose);
      await controlador.iniciarSesion('mozo', '123456');
      await controlador.modificarDetalle(
        '1',
        controlador.productos.first,
        variacion: 1,
      );
      almacenamiento.claveFalloEscritura = 'drafts.v1.demo.1';
      expect(await controlador.enviarPedido('1'), isFalse);
      expect(controlador.borradorDeMesa('1')!.pendiente, isFalse);
      expect((await repositorio.cargar()).pedidos, isEmpty);
      almacenamiento.claveFalloEscritura = null;
      expect(await controlador.enviarPedido('1'), isTrue);
      expect(controlador.pedidos, hasLength(1));
    },
  );

  test('La demo revierte operaciones que no se pudieron guardar', () async {
    final almacenamiento = AlmacenamientoConFallos();
    final repositorio = DemoRepository(
      almacenamiento: almacenamiento,
      demora: Duration.zero,
    );
    final controlador = AppController(
      repositorio: repositorio,
      almacenamiento: almacenamiento,
    );
    addTearDown(controlador.dispose);
    await controlador.iniciarSesion('mozo', '123456');
    await controlador.modificarDetalle(
      '1',
      controlador.productos.first,
      variacion: 1,
    );
    almacenamiento.claveFalloEscritura = 'demo.v1';
    expect(await controlador.enviarPedido('1'), isFalse);
    expect((await repositorio.cargar()).pedidos, isEmpty);
    almacenamiento.claveFalloEscritura = null;
    expect(await controlador.enviarPedido('1'), isTrue);
    final id = controlador.pedidos.single.id;
    almacenamiento.claveFalloEscritura = 'demo.v1';
    expect(
      await controlador.anularPedido(id, 'Cambio del cliente', '2468'),
      isFalse,
    );
    expect(await controlador.entregarPedido(id), isFalse);
    await controlador.actualizarDatos();
    expect(controlador.pedidos.single.estado, OrderStatus.sent);
    almacenamiento.claveFalloEscritura = null;
    await controlador.entregarPedido(id);
    almacenamiento.claveFalloEscritura = 'demo.v1';
    expect(await controlador.cerrarMesa('1'), isFalse);
    await controlador.actualizarDatos();
    expect(controlador.mesas.first.ocupada, isTrue);
    expect(controlador.pedidos.single.fechaCierre, isNull);
    almacenamiento.claveFalloEscritura = null;
    await controlador.cerrarMesa('1');
    almacenamiento.claveFalloEscritura = 'demo.v1';
    expect(await controlador.asignarMesas(['7'], '2468'), isFalse);
    await controlador.actualizarDatos();
    expect(controlador.misMesas.map((mesa) => mesa.id), ['1', '2', '3', '4']);
  });

  test(
    'Anular todos los pedidos conserva la mesa ocupada hasta el cierre',
    () async {
      final almacenamiento = MemoryStore();
      final controlador = AppController(
        repositorio: DemoRepository(
          almacenamiento: almacenamiento,
          demora: Duration.zero,
        ),
        almacenamiento: almacenamiento,
      );
      addTearDown(controlador.dispose);
      await controlador.iniciarSesion('mozo', '123456');
      await controlador.modificarDetalle(
        '1',
        controlador.productos.first,
        variacion: 1,
      );
      await controlador.enviarPedido('1');
      await controlador.anularPedido(
        controlador.pedidos.single.id,
        'El cliente canceló',
        '2468',
      );
      expect(controlador.mesas.first.ocupada, isTrue);
      expect(controlador.mesas.first.totalCentimos, 0);
      expect(await controlador.asignarMesas(['2', '3', '4'], '2468'), isFalse);
      expect(await controlador.cerrarMesa('1'), isTrue);
      expect(controlador.mesas.first.ocupada, isFalse);
    },
  );

  test(
    'Una sesión vencida no cambia la clave de un pedido por confirmar',
    () async {
      final almacenamiento = MemoryStore();
      final controlador = AppController(
        repositorio: RepositorioConSesionVencida(
          almacenamiento: almacenamiento,
        ),
        almacenamiento: almacenamiento,
      );
      addTearDown(controlador.dispose);
      await controlador.iniciarSesion('mozo', '123456');
      await controlador.modificarDetalle(
        '1',
        controlador.productos.first,
        variacion: 1,
      );
      final clave = controlador.borradorDeMesa('1')!.clave;
      expect(await controlador.enviarPedido('1'), isFalse);
      expect(await controlador.enviarPedido('1'), isFalse);
      expect(controlador.borradorDeMesa('1')!.pendiente, isTrue);
      expect(controlador.borradorDeMesa('1')!.clave, clave);
      await controlador.cerrarSesion();
      await controlador.iniciarSesion('mozo', '123456');
      expect(await controlador.enviarPedido('1'), isTrue);
      expect(controlador.pedidos, hasLength(1));
    },
  );

  test(
    'Reintenta tras reinicio sin duplicar un pedido cuya respuesta se perdio',
    () async {
      final almacenamiento = MemoryStore();
      final repositorio = LostResponseRepository(
        almacenamiento: almacenamiento,
      );
      final estadoAplicacion = AppController(
        repositorio: repositorio,
        almacenamiento: almacenamiento,
      );
      await estadoAplicacion.iniciarSesion('mozo', '123456');
      final producto = estadoAplicacion.productos.first;
      await estadoAplicacion.modificarDetalle(
        '1',
        producto,
        variacion: 2,
        observaciones: 'Sin cebolla',
      );
      final clave = estadoAplicacion.borradorDeMesa('1')!.clave;
      expect(await estadoAplicacion.enviarPedido('1'), isFalse);
      expect(estadoAplicacion.borradorDeMesa('1')!.pendiente, isTrue);
      expect(
        await estadoAplicacion.modificarDetalle('1', producto, variacion: 1),
        isFalse,
      );
      expect(estadoAplicacion.borradorDeMesa('1')!.cantidad, 2);
      estadoAplicacion.dispose();
      final reiniciado = AppController(
        repositorio: DemoRepository(
          almacenamiento: almacenamiento,
          demora: Duration.zero,
        ),
        almacenamiento: almacenamiento,
      );
      addTearDown(reiniciado.dispose);
      await reiniciado.iniciarSesion('mozo', '123456');
      expect(reiniciado.borradorDeMesa('1')!.clave, clave);
      expect(await reiniciado.enviarPedido('1'), isTrue);
      expect(reiniciado.pedidos, hasLength(1));
      expect(
        reiniciado.pedidos.single.detalles.single.observaciones,
        'Sin cebolla',
      );
      expect(reiniciado.borradores, isEmpty);
    },
  );

  test(
    'Clave de administrador, exclusividad y borradores protegen asignaciones',
    () async {
      final almacenamiento = MemoryStore();
      final estadoAplicacion = AppController(
        repositorio: DemoRepository(
          almacenamiento: almacenamiento,
          demora: Duration.zero,
        ),
        almacenamiento: almacenamiento,
      );
      addTearDown(estadoAplicacion.dispose);
      await estadoAplicacion.iniciarSesion('mozo', '123456');
      expect(
        await estadoAplicacion.asignarMesas(['1', '7'], 'incorrecta'),
        isFalse,
      );
      expect(estadoAplicacion.misMesas, hasLength(4));
      expect(await estadoAplicacion.asignarMesas(['1', '5'], '2468'), isFalse);
      expect(await estadoAplicacion.asignarMesas(['1', '7'], '2468'), isTrue);
      expect(estadoAplicacion.misMesas.map((mesaActual) => mesaActual.id), [
        '1',
        '7',
      ]);
      await estadoAplicacion.modificarDetalle(
        '7',
        estadoAplicacion.productos.first,
        variacion: 1,
      );
      expect(await estadoAplicacion.asignarMesas(['1'], '2468'), isFalse);
      expect(
        await estadoAplicacion.modificarDetalle(
          '5',
          estadoAplicacion.productos.first,
          variacion: 1,
        ),
        isFalse,
      );
    },
  );

  test(
    'Pedidos adicionales, anulacion autorizada, entrega y nueva atencion',
    () async {
      final almacenamiento = MemoryStore();
      final estadoAplicacion = AppController(
        repositorio: DemoRepository(
          almacenamiento: almacenamiento,
          demora: Duration.zero,
        ),
        almacenamiento: almacenamiento,
      );
      addTearDown(estadoAplicacion.dispose);
      await estadoAplicacion.iniciarSesion('mozo', '123456');
      await estadoAplicacion.modificarDetalle(
        '1',
        estadoAplicacion.productos.first,
        variacion: 1,
      );
      expect(await estadoAplicacion.enviarPedido('1'), isTrue);
      final primerPedido = estadoAplicacion.pedidos.single;
      await estadoAplicacion.modificarDetalle(
        '1',
        estadoAplicacion.productos[1],
        variacion: 1,
      );
      await estadoAplicacion.enviarPedido('1');
      expect(estadoAplicacion.mesas.first.totalCentimos, 4300);
      expect(await estadoAplicacion.cerrarMesa('1'), isFalse);
      final segundoPedido = estadoAplicacion.pedidos.first;
      expect(
        await estadoAplicacion.anularPedido(
          segundoPedido.id,
          'Cliente cambió de opinión',
          '0000',
        ),
        isFalse,
      );
      expect(
        await estadoAplicacion.anularPedido(
          segundoPedido.id,
          'Cliente cambió de opinión',
          '2468',
        ),
        isTrue,
      );
      expect(estadoAplicacion.mesas.first.totalCentimos, 1800);
      await estadoAplicacion.entregarPedido(primerPedido.id);
      await estadoAplicacion.modificarDetalle(
        '1',
        estadoAplicacion.productos[2],
        variacion: 1,
      );
      expect(await estadoAplicacion.cerrarMesa('1'), isFalse);
      await estadoAplicacion.descartarBorrador('1');
      expect(await estadoAplicacion.cerrarMesa('1'), isTrue);
      expect(estadoAplicacion.mesas.first.ocupada, isFalse);
      expect(estadoAplicacion.mesas.first.totalCentimos, 0);
      expect(
        estadoAplicacion.pedidos.every(
          (pedidoActual) => pedidoActual.fechaCierre != null,
        ),
        isTrue,
      );
      await estadoAplicacion.modificarDetalle(
        '1',
        estadoAplicacion.productos[2],
        variacion: 1,
      );
      await estadoAplicacion.enviarPedido('1');
      expect(estadoAplicacion.mesas.first.totalCentimos, 1600);
      expect(
        estadoAplicacion.pedidos.where(
          (pedidoActual) => pedidoActual.fechaCierre == null,
        ),
        hasLength(1),
      );
      // Repetir el cierre de los pedidos anteriores no debe cerrar una atención nueva.
      await estadoAplicacion.repositorio.cerrarMesa('1', [
        primerPedido.id,
        segundoPedido.id,
      ]);
      await estadoAplicacion.actualizarDatos();
      expect(estadoAplicacion.mesas.first.ocupada, isTrue);
      expect(estadoAplicacion.mesas.first.totalCentimos, 1600);
    },
  );

  test('Recupera recibos aunque la mesa cambie de asignacion', () async {
    final almacenamiento = MemoryStore();
    final repositorioDemo = LostResponseRepository(
      almacenamiento: almacenamiento,
    );
    final estadoAplicacion = AppController(
      repositorio: repositorioDemo,
      almacenamiento: almacenamiento,
    );
    addTearDown(estadoAplicacion.dispose);
    await estadoAplicacion.iniciarSesion('mozo', '123456');
    await estadoAplicacion.modificarDetalle(
      '1',
      estadoAplicacion.productos.first,
      variacion: 1,
    );
    expect(await estadoAplicacion.enviarPedido('1'), isFalse);
    final pedidoRecibido = (await repositorioDemo.cargar()).pedidos.single;
    await repositorioDemo.entregarPedido(pedidoRecibido.id);
    await repositorioDemo.cerrarMesa('1', [pedidoRecibido.id]);
    await repositorioDemo.asignarMesas(['2', '3', '4'], '2468');
    await estadoAplicacion.actualizarDatos();
    expect(
      estadoAplicacion.misMesas.any((mesaActual) => mesaActual.id == '1'),
      isFalse,
    );
    expect(
      await estadoAplicacion.asignarMesas(['2', '3', '4'], '2468'),
      isTrue,
    );
    expect(await estadoAplicacion.enviarPedido('1'), isTrue);
    expect(estadoAplicacion.pedidos, hasLength(1));
    expect(estadoAplicacion.borradores, isEmpty);
  });

  test(
    'Borradores se separan por usuario y un envio sin red se recupera',
    () async {
      final almacenamiento = MemoryStore();
      final repositorioDemo = DemoRepository(
        almacenamiento: almacenamiento,
        demora: Duration.zero,
      );
      final estadoAplicacion = AppController(
        repositorio: repositorioDemo,
        almacenamiento: almacenamiento,
      );
      addTearDown(estadoAplicacion.dispose);
      await estadoAplicacion.iniciarSesion('mozo', '123456');
      await estadoAplicacion.modificarDetalle(
        '1',
        estadoAplicacion.productos.first,
        variacion: 1,
      );
      repositorioDemo.sinConexion = true;
      expect(await estadoAplicacion.enviarPedido('1'), isFalse);
      final clave = estadoAplicacion.borradorDeMesa('1')!.clave;
      repositorioDemo.sinConexion = false;
      await estadoAplicacion.cerrarSesion();
      await estadoAplicacion.iniciarSesion('lucia', '123456');
      expect(estadoAplicacion.borradores, isEmpty);
      await estadoAplicacion.cerrarSesion();
      await estadoAplicacion.iniciarSesion('mozo', '123456');
      expect(estadoAplicacion.borradorDeMesa('1')!.clave, clave);
      expect(await estadoAplicacion.enviarPedido('1'), isTrue);
      expect(estadoAplicacion.pedidos, hasLength(1));
    },
  );
}
