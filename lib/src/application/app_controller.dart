import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/repository.dart';
import '../domain/models.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.repositorio,
    required this.almacenamiento,
    this.espacioDatos = 'demo',
  });
  final RestaurantRepository repositorio;
  final LocalStore almacenamiento;
  final String espacioDatos;
  Waiter? usuario;
  List<DiningTable> mesas = [];
  List<MenuProduct> productos = [];
  List<ServiceOrder> pedidos = [];
  final Map<String, OrderDraft> borradores = {};
  bool procesando = false;
  String? error;
  DateTime? ultimaActualizacion;
  Future<void> _escrituras = Future.value();
  bool _borradoresCargados = false;
  bool get esDemo => repositorio.esDemo;
  List<DiningTable> get misMesas =>
      mesas.where((mesaActual) => mesaActual.idMozo == usuario?.id).toList();
  List<ServiceOrder> get misPedidos => pedidos
      .where((pedidoActual) => pedidoActual.idMozo == usuario?.id)
      .toList();
  OrderDraft? borradorDeMesa(String idMesa) => borradores[idMesa];
  String get _claveBorradores => 'drafts.v1.$espacioDatos.${usuario!.id}';
  String _generarClave() =>
      '${DateTime.now().microsecondsSinceEpoch}-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  String _obtenerMensaje(Object excepcion) => excepcion is AppException
      ? excepcion.mensaje
      : 'No se pudo completar la operación. Reintenta; tus pedidos se conservarán.';
  void limpiarError() {
    error = null;
    notifyListeners();
  }

  Future<void> _cargarBorradores() async {
    if (_borradoresCargados) {
      return;
    }
    try {
      final texto = await almacenamiento.leer(_claveBorradores);
      final recuperados = <String, OrderDraft>{};
      if (texto != null) {
        for (final elemento in jsonDecode(texto) as List) {
          final borrador = OrderDraft.fromJson(
            Map<String, dynamic>.from(elemento as Map),
          );
          recuperados[borrador.idMesa] = borrador;
        }
      }
      borradores
        ..clear()
        ..addAll(recuperados);
      _borradoresCargados = true;
    } catch (_) {
      throw const AppException(
        'No se pudieron recuperar los borradores. Usa Actualizar datos para reintentar; la copia guardada se conserva.',
      );
    }
  }

  Future<void> _guardarBorradores() async {
    await _cargarBorradores();
    final clave = _claveBorradores;
    final valor = jsonEncode(
      borradores.values
          .map((borradorActual) => borradorActual.toJson())
          .toList(),
    );
    final siguiente = _escrituras.then(
      (_) => almacenamiento.guardar(clave, valor),
    );
    _escrituras = siguiente.catchError((Object _) {});
    await siguiente;
  }

  Future<void> _cargarDatos() async {
    await _cargarBorradores();
    final datos = await repositorio.cargar();
    mesas = datos.mesas;
    productos = datos.productos;
    pedidos = datos.pedidos;
    ultimaActualizacion = DateTime.now();
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    if (procesando) {
      return false;
    }
    procesando = true;
    error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } catch (excepcion) {
      error = _obtenerMensaje(excepcion);
      return false;
    } finally {
      procesando = false;
      notifyListeners();
    }
  }

  Future<bool> iniciarSesion(String nombreUsuario, String contrasena) =>
      _ejecutar(() async {
        final usuarioAutenticado = await repositorio.iniciarSesion(
          nombreUsuario.trim(),
          contrasena,
        );
        usuario = usuarioAutenticado;
        _borradoresCargados = false;
        borradores.clear();
        mesas = [];
        productos = [];
        pedidos = [];
        ultimaActualizacion = null;
        try {
          await _cargarDatos();
        } catch (excepcion) {
          // Conserva la sesión para reintentar si falla la descarga inicial.
          error = _obtenerMensaje(excepcion);
        }
      });
  Future<bool> actualizarDatos() => _ejecutar(_cargarDatos);
  Future<void> cerrarSesion() async {
    if (procesando) {
      return;
    }
    procesando = true;
    error = null;
    notifyListeners();
    try {
      await _guardarBorradores();
    } catch (excepcion) {
      error =
          'No se pudieron guardar los borradores. Reintenta antes de salir.';
      procesando = false;
      notifyListeners();
      return;
    }
    try {
      await repositorio.cerrarSesion();
    } catch (_) {
      /* El repositorio elimina el token de la sesión local. */
    }
    usuario = null;
    _borradoresCargados = false;
    borradores.clear();
    mesas = [];
    productos = [];
    pedidos = [];
    ultimaActualizacion = null;
    procesando = false;
    notifyListeners();
  }

  void _validarMesa(String idMesa) {
    if (!misMesas.any((mesaActual) => mesaActual.id == idMesa)) {
      throw const AppException(
        'La mesa ya no está asignada a tu usuario. Actualiza tus mesas.',
        rechazoDefinitivo: true,
      );
    }
  }

  Future<bool> modificarDetalle(
    String idMesa,
    MenuProduct producto, {
    int variacion = 0,
    String? observaciones,
  }) => _ejecutar(() async {
    await _cargarBorradores();
    _validarMesa(idMesa);
    final existente = borradores[idMesa];
    if (existente?.pendiente ?? false) {
      throw const AppException(
        'Confirma el envío pendiente antes de editar el pedido.',
      );
    }
    if (observaciones != null && observaciones.trim().length > 250) {
      throw const AppException('La observación admite hasta 250 caracteres.');
    }
    if (variacion > 0 &&
        !productos.any(
          (actual) => actual.id == producto.id && actual.disponible,
        )) {
      throw const AppException('Este plato no está disponible.');
    }
    final indice =
        existente?.detalles.indexWhere(
          (detalleActual) => detalleActual.idProducto == producto.id,
        ) ??
        -1;
    final cantidad =
        (indice < 0 ? 0 : existente!.detalles[indice].cantidad) + variacion;
    if (cantidad > 99) {
      throw const AppException('El máximo por plato es 99 unidades.');
    }
    if (indice < 0 && variacion <= 0) {
      return;
    }
    final borradorActual =
        existente ?? OrderDraft(idMesa: idMesa, clave: _generarClave());
    borradores[idMesa] = borradorActual;
    if (indice < 0) {
      if (variacion > 0) {
        borradorActual.detalles.add(
          OrderLine(
            idProducto: producto.id,
            nombre: producto.nombre,
            precioCentimos: producto.precioCentimos,
            cantidad: variacion,
            observaciones: observaciones?.trim() ?? '',
          ),
        );
      }
    } else {
      final anterior = borradorActual.detalles[indice];
      if (cantidad <= 0) {
        borradorActual.detalles.removeAt(indice);
      } else {
        borradorActual.detalles[indice] = anterior.actualizar(
          cantidad: cantidad,
          observaciones: observaciones?.trim(),
        );
      }
    }
    if (borradorActual.detalles.isEmpty) {
      borradores.remove(idMesa);
    }
    await _guardarBorradores();
  });
  Future<bool> descartarBorrador(String idMesa) => _ejecutar(() async {
    await _cargarBorradores();
    if (borradores[idMesa]?.pendiente ?? false) {
      throw const AppException(
        'Primero confirma el envío pendiente con el servidor.',
      );
    }
    borradores.remove(idMesa);
    await _guardarBorradores();
  });
  Future<bool> asignarMesas(List<String> ids, String contrasena) =>
      _ejecutar(() async {
        await _cargarBorradores();
        if (borradores.values.any(
          (borradorActual) =>
              borradorActual.detalles.isNotEmpty &&
              misMesas.any(
                (mesaActual) => mesaActual.id == borradorActual.idMesa,
              ) &&
              !ids.contains(borradorActual.idMesa),
        )) {
          throw const AppException(
            'Envía o descarta los borradores antes de quitar sus mesas.',
          );
        }
        await repositorio.asignarMesas(ids, contrasena);
        await _actualizarTrasOperacion();
      });
  Future<void> _actualizarTrasOperacion() async {
    try {
      await _cargarDatos();
    } catch (excepcion) {
      error =
          'La operación se confirmó. No pudimos actualizar la vista: ${_obtenerMensaje(excepcion)}';
    }
  }

  Future<bool> enviarPedido(String idMesa) => _ejecutar(() async {
    await _cargarBorradores();
    final borradorActual = borradores[idMesa];
    if (borradorActual == null || borradorActual.detalles.isEmpty) {
      throw const AppException('Agrega platos a tu pedido.');
    }
    // El recibo debe poder recuperarse aunque la mesa cambie de mozo.
    // En envíos pendientes, el servidor consulta el recibo antes de validar la asignación.
    if (!borradorActual.pendiente) {
      _validarMesa(idMesa);
    }
    final estabaPendiente = borradorActual.pendiente;
    borradorActual.pendiente = true;
    // Guarda la clave y el contenido exacto del pedido antes de enviarlo.
    try {
      await _guardarBorradores();
    } catch (_) {
      // Sin guardar la intención de envío, todavía no se contacta al servidor.
      borradorActual.pendiente = estabaPendiente;
      rethrow;
    }
    ServiceOrder pedido;
    try {
      pedido = await repositorio.enviarPedido(borradorActual);
    } on AppException catch (excepcion) {
      if (excepcion.rechazoDefinitivo &&
          !(estabaPendiente && excepcion.sesionVencida)) {
        borradores[idMesa] = OrderDraft(
          idMesa: idMesa,
          clave: _generarClave(),
          detalles: List.of(borradorActual.detalles),
        );
        await _guardarBorradores();
      }
      rethrow;
    }
    borradores.remove(idMesa);
    pedidos = [
      pedido,
      ...pedidos.where((pedidoActual) => pedidoActual.id != pedido.id),
    ];
    try {
      await _guardarBorradores();
    } catch (_) {
      error = 'Pedido confirmado. No se pudo limpiar la copia local; un reintento conservará su identificador.';
    }
    await _actualizarTrasOperacion();
  });
  Future<bool> anularPedido(String id, String motivo, String contrasena) =>
      _ejecutar(() async {
        await repositorio.anularPedido(id, motivo, contrasena);
        await _actualizarTrasOperacion();
      });
  Future<bool> entregarPedido(String id) => _ejecutar(() async {
    await repositorio.entregarPedido(id);
    await _actualizarTrasOperacion();
  });
  Future<bool> cerrarMesa(String idMesa) => _ejecutar(() async {
    await _cargarBorradores();
    if (borradores[idMesa]?.detalles.isNotEmpty ?? false) {
      throw const AppException(
        'Envía o descarta el borrador antes de cerrar la mesa.',
      );
    }
    final ids = misPedidos
        .where(
          (pedidoActual) =>
              pedidoActual.idMesa == idMesa && pedidoActual.fechaCierre == null,
        )
        .map((pedidoActual) => pedidoActual.id)
        .toList();
    await repositorio.cerrarMesa(idMesa, ids);
    await _actualizarTrasOperacion();
  });
  @override
  void dispose() {
    repositorio.dispose();
    super.dispose();
  }
}
