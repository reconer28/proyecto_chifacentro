import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/models.dart';
import 'repository.dart';

/// El contrato propuesto para Laravel se documenta en docs/API_CONTRACT.md.
class ApiRepository implements RestaurantRepository {
  ApiRepository({required this.urlBase, HttpClient? cliente})
    : _cliente = cliente ?? HttpClient() {
    _cliente.connectionTimeout = const Duration(seconds: 15);
  }
  final String urlBase;
  final HttpClient _cliente;
  String? _token;
  @override
  bool get esDemo => false;
  Future<dynamic> _solicitar(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
    String? claveIdempotencia,
  }) async {
    final base = Uri.tryParse(urlBase);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const AppException(
        'Configura API_BASE_URL con la URL HTTPS de Laravel, terminada en /api/v1.',
        rechazoDefinitivo: true,
      );
    }
    HttpClientRequest? solicitud;
    var tiempoAgotado = false;
    try {
      return await (() async {
        solicitud = await _cliente.openUrl(
          metodo,
          Uri.parse('${urlBase.replaceAll(RegExp(r'/+$'), '')}$ruta'),
        );
        if (tiempoAgotado) {
          solicitud!.abort();
          throw TimeoutException('La conexión llegó fuera de plazo.');
        }
        solicitud!.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (_token != null) {
          solicitud!.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $_token',
          );
        }
        if (claveIdempotencia != null) {
          solicitud!.headers.set('Idempotency-Key', claveIdempotencia);
        }
        if (cuerpo != null) {
          solicitud!.headers.contentType = ContentType.json;
          solicitud!.write(jsonEncode(cuerpo));
        }
        final respuesta = await solicitud!.close();
        final textoOriginal = await respuesta.transform(utf8.decoder).join();
        dynamic contenidoRespuesta;
        try {
          contenidoRespuesta = textoOriginal.isEmpty
              ? null
              : jsonDecode(textoOriginal);
        } on FormatException {
          if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
            throw const AppException(
              'El servidor no devolvió una respuesta JSON válida.',
            );
          }
        }
        if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
          final estado = respuesta.statusCode;
          throw AppException(
            estado == 401
                ? 'Tu sesión venció. Vuelve a iniciar sesión; tus borradores están guardados.'
                : contenidoRespuesta is Map &&
                      contenidoRespuesta['message'] is String
                ? contenidoRespuesta['message'] as String
                : 'No se pudo completar la operación ($estado).',
            sesionVencida: estado == 401,
            rechazoDefinitivo: [400, 401, 403, 404, 422].contains(estado),
          );
        }
        return contenidoRespuesta is Map ? contenidoRespuesta['data'] : null;
      })().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      tiempoAgotado = true;
      solicitud?.abort();
      throw const AppException(
        'La respuesta está tardando. Conservamos tu pedido para reintentar.',
      );
    } on SocketException {
      throw const AppException(
        'No pudimos conectar con el servidor. Revisa tu conexión y reintenta.',
      );
    } on HttpException {
      throw const AppException(
        'La conexión se interrumpió. Reintenta para confirmar el pedido.',
      );
    } on HandshakeException {
      throw const AppException(
        'No se pudo establecer una conexión segura con Laravel.',
      );
    }
  }

  Map<String, dynamic> _convertirMapa(dynamic valor) =>
      Map<String, dynamic>.from(valor as Map);
  @override
  Future<Waiter> iniciarSesion(String nombreUsuario, String contrasena) async {
    final datosJson = _convertirMapa(
      await _solicitar(
        'POST',
        '/auth/login',
        cuerpo: {
          'username': nombreUsuario,
          'password': contrasena,
          'device_name': 'Chifa Centro Android',
        },
      ),
    );
    final usuario = Waiter.fromJson(_convertirMapa(datosJson['user']));
    _token = datosJson['token'] as String;
    return usuario;
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _solicitar('POST', '/auth/logout');
    } finally {
      _token = null;
    }
  }

  @override
  Future<RestaurantSnapshot> cargar() async {
    final valores = await Future.wait([
      _solicitar('GET', '/tables'),
      _solicitar('GET', '/menu'),
      _solicitar('GET', '/orders'),
    ]);
    return RestaurantSnapshot(
      mesas: (valores[0] as List)
          .map(
            (valorActual) => DiningTable.fromJson(_convertirMapa(valorActual)),
          )
          .toList(),
      productos: (valores[1] as List)
          .map(
            (valorActual) => MenuProduct.fromJson(_convertirMapa(valorActual)),
          )
          .toList(),
      pedidos: (valores[2] as List)
          .map(
            (valorActual) => ServiceOrder.fromJson(_convertirMapa(valorActual)),
          )
          .toList(),
    );
  }

  @override
  Future<void> asignarMesas(
    List<String> idsMesas,
    String claveAdministrador,
  ) async {
    await _solicitar(
      'PUT',
      '/me/tables',
      cuerpo: {'table_ids': idsMesas, 'admin_password': claveAdministrador},
    );
  }

  @override
  Future<ServiceOrder> enviarPedido(OrderDraft borrador) async =>
      ServiceOrder.fromJson(
        _convertirMapa(
          await _solicitar(
            'POST',
            '/orders',
            claveIdempotencia: borrador.clave,
            cuerpo: {
              'table_id': borrador.idMesa,
              'items': borrador.detalles
                  .map(
                    (detalleActual) => {
                      'product_id': detalleActual.idProducto,
                      'quantity': detalleActual.cantidad,
                      'notes': detalleActual.observaciones,
                    },
                  )
                  .toList(),
            },
          ),
        ),
      );
  @override
  Future<void> anularPedido(
    String idPedido,
    String motivo,
    String claveAdministrador,
  ) async {
    await _solicitar(
      'POST',
      '/orders/${Uri.encodeComponent(idPedido)}/cancel',
      cuerpo: {'reason': motivo, 'admin_password': claveAdministrador},
    );
  }

  @override
  Future<void> entregarPedido(String idPedido) async {
    await _solicitar(
      'POST',
      '/orders/${Uri.encodeComponent(idPedido)}/deliver',
    );
  }

  @override
  Future<void> cerrarMesa(
    String idMesa,
    List<String> idsPedidosEsperados,
  ) async {
    await _solicitar(
      'POST',
      '/tables/${Uri.encodeComponent(idMesa)}/close',
      cuerpo: {'order_ids': idsPedidosEsperados},
    );
  }

  @override
  void dispose() => _cliente.close(force: true);
}
