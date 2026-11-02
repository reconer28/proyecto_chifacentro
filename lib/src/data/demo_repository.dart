import 'dart:convert';

import '../domain/models.dart';
import 'local_store.dart';
import 'repository.dart';

class DemoRepository implements RestaurantRepository {
  DemoRepository({
    required this.almacenamiento,
    this.demora = const Duration(milliseconds: 280),
  });
  final LocalStore almacenamiento;
  final Duration demora;
  bool sinConexion = false;
  Waiter? _usuario;
  bool _datosCargados = false;
  List<DiningTable> _mesas = List.generate(
    12,
    (indice) => DiningTable(
      id: '${indice + 1}',
      numero: indice + 1,
      capacidad: indice % 3 == 0 ? 6 : 4,
      zona: indice < 8 ? 'Salón principal' : 'Terraza',
      idMozo: indice < 4 ? '1' : (indice == 4 || indice == 5 ? '2' : null),
    ),
  );
  List<ServiceOrder> _pedidos = [];
  final Map<String, String> _recibos = {};
  static const productos = [
    MenuProduct(
      id: '1',
      nombre: 'Arroz chaufa de pollo',
      descripcion: 'Arroz al wok, pollo, huevo y cebollita china.',
      categoria: 'Chaufas',
      precioCentimos: 1800,
      destacado: true,
    ),
    MenuProduct(
      id: '2',
      nombre: 'Chaufa especial',
      descripcion: 'Pollo, cerdo y langostinos al fuego del wok.',
      categoria: 'Chaufas',
      precioCentimos: 2500,
      destacado: true,
    ),
    MenuProduct(
      id: '3',
      nombre: 'Chaufa de verduras',
      descripcion: 'Verduras frescas, huevo y nuestro toque de sillao.',
      categoria: 'Chaufas',
      precioCentimos: 1600,
    ),
    MenuProduct(
      id: '4',
      nombre: 'Tallarín saltado de pollo',
      descripcion: 'Fideos, verduras crocantes y pollo salteado.',
      categoria: 'Tallarines',
      precioCentimos: 2000,
    ),
    MenuProduct(
      id: '5',
      nombre: 'Aeropuerto',
      descripcion: 'El encuentro del chaufa y el tallarín, con pollo.',
      categoria: 'Especiales',
      precioCentimos: 2300,
      destacado: true,
    ),
    MenuProduct(
      id: '6',
      nombre: 'Pollo tipakay',
      descripcion: 'Pollo crocante bañado en salsa de tamarindo.',
      categoria: 'Especiales',
      precioCentimos: 2400,
    ),
    MenuProduct(
      id: '7',
      nombre: 'Wantán frito',
      descripcion: 'Seis unidades crocantes con salsa de tamarindo.',
      categoria: 'Entradas',
      precioCentimos: 1200,
    ),
    MenuProduct(
      id: '8',
      nombre: 'Sopa wantán',
      descripcion: 'Caldo de la casa, wantanes, pollo y verduras.',
      categoria: 'Entradas',
      precioCentimos: 1400,
    ),
    MenuProduct(
      id: '9',
      nombre: 'Inca Kola 500 ml',
      descripcion: 'Bien helada, para acompañar tu pedido.',
      categoria: 'Bebidas',
      precioCentimos: 500,
    ),
    MenuProduct(
      id: '10',
      nombre: 'Chicha morada',
      descripcion: 'Un vaso de nuestra chicha de la casa.',
      categoria: 'Bebidas',
      precioCentimos: 600,
    ),
    MenuProduct(
      id: '11',
      nombre: 'Tallarín de langostinos',
      descripcion: 'Langostinos salteados con verduras de estación.',
      categoria: 'Tallarines',
      precioCentimos: 2800,
      disponible: false,
    ),
  ];
  @override
  bool get esDemo => true;
  Future<void> _comprobarSesion() async {
    if (demora != Duration.zero) {
      await Future<void>.delayed(demora);
    }
    if (sinConexion) {
      throw const AppException(
        'Sin conexión de prueba. Tu borrador está guardado; vuelve a conectar desde Mi cuenta.',
      );
    }
    if (_usuario == null) {
      throw const AppException(
        'Inicia sesión para continuar.',
        sesionVencida: true,
        rechazoDefinitivo: true,
      );
    }
  }

  @override
  Future<Waiter> iniciarSesion(String nombreUsuario, String contrasena) async {
    if (demora != Duration.zero) {
      await Future<void>.delayed(demora);
    }
    if (!['mozo', 'lucia'].contains(nombreUsuario) || contrasena != '123456') {
      throw const AppException(
        'Usuario o contraseña incorrectos.',
        rechazoDefinitivo: true,
      );
    }
    _usuario = Waiter(
      id: nombreUsuario == 'mozo' ? '1' : '2',
      nombre: nombreUsuario == 'mozo' ? 'Diego Ramírez' : 'Lucía Torres',
      nombreUsuario: nombreUsuario,
    );
    return _usuario!;
  }

  Future<void> _guardar() => almacenamiento.guardar(
    'demo.v1',
    jsonEncode({
      'tables': _mesas.map((mesaActual) => mesaActual.toJson()).toList(),
      'orders': _pedidos.map((pedidoActual) => pedidoActual.toJson()).toList(),
      'receipts': _recibos,
    }),
  );

  Future<T> _guardarCambio<T>(T Function() cambio) async {
    final mesasAnteriores = List<DiningTable>.of(_mesas);
    final pedidosAnteriores = List<ServiceOrder>.of(_pedidos);
    final recibosAnteriores = Map<String, String>.of(_recibos);
    try {
      final resultado = cambio();
      await _guardar();
      return resultado;
    } catch (_) {
      // Un fallo de almacenamiento no debe dejar una operación confirmada en memoria.
      _mesas = mesasAnteriores;
      _pedidos = pedidosAnteriores;
      _recibos
        ..clear()
        ..addAll(recibosAnteriores);
      rethrow;
    }
  }

  @override
  Future<RestaurantSnapshot> cargar() async {
    await _comprobarSesion();
    if (!_datosCargados) {
      final textoOriginal = await almacenamiento.leer('demo.v1');
      if (textoOriginal != null) {
        final datosJson = jsonDecode(textoOriginal) as Map<String, dynamic>;
        _mesas = (datosJson['tables'] as List)
            .map(
              (valorActual) => DiningTable.fromJson(
                Map<String, dynamic>.from(valorActual as Map),
              ),
            )
            .toList();
        _pedidos = (datosJson['orders'] as List)
            .map(
              (valorActual) => ServiceOrder.fromJson(
                Map<String, dynamic>.from(valorActual as Map),
              ),
            )
            .toList();
        _recibos.addAll(Map<String, String>.from(datosJson['receipts'] as Map));
      }
      _datosCargados = true;
    }
    return RestaurantSnapshot(
      mesas: List.of(_mesas),
      productos: productos,
      pedidos: _pedidos
          .where((pedidoActual) => pedidoActual.idMozo == _usuario!.id)
          .toList()
          .reversed
          .toList(),
    );
  }

  void _validarAdministrador(String contrasena) {
    if (contrasena != '2468') {
      throw const AppException(
        'La clave del administrador es incorrecta.',
        rechazoDefinitivo: true,
      );
    }
  }

  DiningTable _mesaPropia(String id) {
    final mesa = _mesas.firstWhere((mesaActual) => mesaActual.id == id);
    if (mesa.idMozo != _usuario!.id) {
      throw const AppException(
        'Esta mesa no está asignada a tu usuario.',
        rechazoDefinitivo: true,
      );
    }
    return mesa;
  }

  @override
  Future<void> asignarMesas(
    List<String> idsMesas,
    String claveAdministrador,
  ) async {
    await _comprobarSesion();
    _validarAdministrador(claveAdministrador);
    if (idsMesas.toSet().length != idsMesas.length ||
        idsMesas.any((id) => !_mesas.any((mesa) => mesa.id == id))) {
      throw const AppException(
        'La selección contiene mesas inválidas.',
        rechazoDefinitivo: true,
      );
    }
    for (final mesaActual in _mesas) {
      if (idsMesas.contains(mesaActual.id) &&
          mesaActual.idMozo != null &&
          mesaActual.idMozo != _usuario!.id) {
        throw const AppException(
          'Una mesa ya está asignada a otro mozo.',
          rechazoDefinitivo: true,
        );
      }
      if (mesaActual.idMozo == _usuario!.id &&
          mesaActual.ocupada &&
          !idsMesas.contains(mesaActual.id)) {
        throw const AppException(
          'Cierra la atención antes de quitar una mesa ocupada.',
          rechazoDefinitivo: true,
        );
      }
    }
    await _guardarCambio(() {
      _mesas = _mesas
          .map(
            (mesaActual) => idsMesas.contains(mesaActual.id)
                ? mesaActual.actualizar(idMozo: _usuario!.id)
                : (mesaActual.idMozo == _usuario!.id
                      ? mesaActual.actualizar(quitarMozo: true)
                      : mesaActual),
          )
          .toList();
    });
  }

  @override
  Future<ServiceOrder> enviarPedido(OrderDraft borrador) async {
    await _comprobarSesion();
    final recibo = _recibos[borrador.clave];
    if (recibo != null) {
      final pedido = _pedidos.firstWhere((actual) => actual.id == recibo);
      if (pedido.idMozo != _usuario!.id) {
        throw const AppException(
          'El pedido pertenece a otro mozo.',
          rechazoDefinitivo: true,
        );
      }
      return pedido;
    }
    final mesa = _mesaPropia(borrador.idMesa);
    if (borrador.detalles.isEmpty) {
      throw const AppException(
        'Agrega al menos un plato.',
        rechazoDefinitivo: true,
      );
    }
    final detalles = borrador.detalles.map((detalle) {
      final producto = productos.firstWhere(
        (productoActual) => productoActual.id == detalle.idProducto,
      );
      if (!producto.disponible ||
          detalle.cantidad < 1 ||
          detalle.cantidad > 99 ||
          detalle.observaciones.length > 250) {
        throw const AppException(
          'Revisa la disponibilidad y las cantidades.',
          rechazoDefinitivo: true,
        );
      }
      return OrderLine(
        idProducto: producto.id,
        nombre: producto.nombre,
        precioCentimos: producto.precioCentimos,
        cantidad: detalle.cantidad,
        observaciones: detalle.observaciones,
      );
    }).toList();
    final pedido = ServiceOrder(
      id: '${1001 + _pedidos.length}',
      idMesa: mesa.id,
      numeroMesa: mesa.numero,
      idMozo: _usuario!.id,
      fechaCreacion: DateTime.now(),
      detalles: detalles,
    );
    return _guardarCambio(() {
      _pedidos.add(pedido);
      _recibos[borrador.clave] = pedido.id;
      _recalcular();
      return pedido;
    });
  }

  void _recalcular() {
    _mesas = _mesas.map((mesaActual) {
      final atencion = _pedidos.where(
        (pedidoActual) =>
            pedidoActual.idMesa == mesaActual.id &&
            pedidoActual.fechaCierre == null,
      );
      final activos = atencion.where(
        (pedido) => pedido.estado != OrderStatus.cancelled,
      );
      return mesaActual.actualizar(
        ocupada: atencion.isNotEmpty,
        totalCentimos: activos.fold<int>(
          0,
          (suma, pedidoActual) => suma + pedidoActual.totalCentimos,
        ),
      );
    }).toList();
  }

  ServiceOrder _pedidoPropio(String id) {
    final pedido = _pedidos.firstWhere((pedidoActual) => pedidoActual.id == id);
    if (pedido.idMozo != _usuario!.id) {
      throw const AppException(
        'El pedido pertenece a otro mozo.',
        rechazoDefinitivo: true,
      );
    }
    _mesaPropia(pedido.idMesa);
    if (pedido.fechaCierre != null || pedido.estado == OrderStatus.cancelled) {
      throw const AppException(
        'El pedido ya está cerrado o anulado.',
        rechazoDefinitivo: true,
      );
    }
    return pedido;
  }

  @override
  Future<void> anularPedido(
    String idPedido,
    String motivo,
    String claveAdministrador,
  ) async {
    await _comprobarSesion();
    _validarAdministrador(claveAdministrador);
    final pedido = _pedidoPropio(idPedido);
    if (pedido.estado != OrderStatus.sent || motivo.trim().isEmpty) {
      throw const AppException(
        'Solo puedes anular pedidos enviados indicando un motivo.',
        rechazoDefinitivo: true,
      );
    }
    await _guardarCambio(() {
      _pedidos[_pedidos.indexOf(pedido)] = pedido.actualizar(
        estado: OrderStatus.cancelled,
        motivoAnulacion: motivo.trim(),
      );
      _recalcular();
    });
  }

  @override
  Future<void> entregarPedido(String idPedido) async {
    await _comprobarSesion();
    final pedido = _pedidoPropio(idPedido);
    await _guardarCambio(() {
      _pedidos[_pedidos.indexOf(pedido)] = pedido.actualizar(
        estado: OrderStatus.delivered,
      );
    });
  }

  @override
  Future<void> cerrarMesa(
    String idMesa,
    List<String> idsPedidosEsperados,
  ) async {
    await _comprobarSesion();
    _mesaPropia(idMesa);
    final esperados = _pedidos
        .where(
          (pedidoActual) =>
              idsPedidosEsperados.contains(pedidoActual.id) &&
              pedidoActual.idMesa == idMesa,
        )
        .toList();
    if (idsPedidosEsperados.isEmpty ||
        esperados.length != idsPedidosEsperados.length) {
      throw const AppException(
        'Actualiza los pedidos de la mesa antes de cerrarla.',
        rechazoDefinitivo: true,
      );
    }
    if (esperados.every((pedidoActual) => pedidoActual.fechaCierre != null)) {
      return;
    }
    final idsActuales = _pedidos
        .where(
          (pedidoActual) =>
              pedidoActual.idMesa == idMesa && pedidoActual.fechaCierre == null,
        )
        .map((pedidoActual) => pedidoActual.id)
        .toSet();
    if (idsActuales.length != idsPedidosEsperados.length ||
        !idsActuales.containsAll(idsPedidosEsperados)) {
      throw const AppException(
        'Los pedidos cambiaron. Actualiza la mesa antes de cerrarla.',
        rechazoDefinitivo: true,
      );
    }
    if (_pedidos.any(
      (pedidoActual) =>
          pedidoActual.idMesa == idMesa &&
          pedidoActual.fechaCierre == null &&
          pedidoActual.estado != OrderStatus.cancelled &&
          pedidoActual.estado != OrderStatus.delivered,
    )) {
      throw const AppException(
        'Marca los pedidos como entregados antes de cerrar la mesa.',
        rechazoDefinitivo: true,
      );
    }
    await _guardarCambio(() {
      _pedidos = _pedidos
          .map(
            (pedidoActual) =>
                pedidoActual.idMesa == idMesa &&
                    pedidoActual.fechaCierre == null
                ? pedidoActual.actualizar(fechaCierre: DateTime.now())
                : pedidoActual,
          )
          .toList();
      _recalcular();
    });
  }

  @override
  Future<void> cerrarSesion() async {
    _usuario = null;
    sinConexion = false;
  }

  @override
  void dispose() {}
}
