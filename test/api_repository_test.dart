import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_chifacentro/src/data/api_repository.dart';
import 'package:proyecto_chifacentro/src/domain/models.dart';

class StubHeaders implements HttpHeaders {
  final Map<String, Object> valores = {};
  @override
  void set(String nombre, Object valor, {bool preserveHeaderCase = false}) {
    valores[nombre] = valor;
  }

  @override
  set contentType(ContentType? valor) {
    valores['content-type'] = '$valor';
  }

  @override
  dynamic noSuchMethod(Invocation invocacion) => super.noSuchMethod(invocacion);
}

class StubResponse extends Stream<List<int>> implements HttpClientResponse {
  StubResponse(this.statusCode, this.cuerpo);
  @override
  final int statusCode;
  final String cuerpo;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(utf8.encode(cuerpo)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocacion) => super.noSuchMethod(invocacion);
}

class StubRequest implements HttpClientRequest {
  StubRequest(this.method, this.uri, this.respuesta);
  @override
  final String method;
  @override
  final Uri uri;
  final StubResponse respuesta;
  final cuerpo = StringBuffer();
  bool abortada = false;
  bool cerrada = false;
  @override
  final StubHeaders headers = StubHeaders();
  @override
  void write(Object? objeto) => cuerpo.write(objeto);
  @override
  Future<HttpClientResponse> close() async {
    cerrada = true;
    return respuesta;
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    abortada = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocacion) => super.noSuchMethod(invocacion);
}

class StubClient implements HttpClient {
  final List<StubResponse> respuestas = [];
  final List<StubRequest> solicitudes = [];
  void responder(Object? datos, {int estado = 200}) =>
      respuestas.add(StubResponse(estado, jsonEncode({'data': datos})));
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final solicitud = StubRequest(method, url, respuestas.removeAt(0));
    solicitudes.add(solicitud);
    return solicitud;
  }

  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocacion) => super.noSuchMethod(invocacion);
}

class ClienteConexionLenta extends StubClient {
  final conexion = Completer<HttpClientRequest>();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => conexion.future;
}

void main() {
  testWidgets('No envía una solicitud cuya conexión llegó después del plazo', (
    probador,
  ) async {
    final cliente = ClienteConexionLenta();
    final api = ApiRepository(
      urlBase: 'https://chifa.test/api/v1',
      cliente: cliente,
    );
    addTearDown(api.dispose);
    final verificacion = expectLater(
      api.entregarPedido('1'),
      throwsA(isA<AppException>()),
    );
    await probador.pump(const Duration(seconds: 21));
    await verificacion;
    final solicitud = StubRequest(
      'POST',
      Uri.parse('https://chifa.test/api/v1/orders/1/deliver'),
      StubResponse(204, ''),
    );
    cliente.conexion.complete(solicitud);
    await probador.pump();
    expect(solicitud.abortada, isTrue);
    expect(solicitud.cerrada, isFalse);
    expect(solicitud.cuerpo.toString(), isEmpty);
  });

  test(
    'Conserva el estado HTTP cuando el error del servidor no es JSON',
    () async {
      final cliente = StubClient();
      final api = ApiRepository(
        urlBase: 'https://chifa.test/api/v1',
        cliente: cliente,
      );
      addTearDown(api.dispose);
      cliente.respuestas.add(StubResponse(401, '<html>Sesión vencida</html>'));
      await expectLater(
        api.entregarPedido('1'),
        throwsA(
          isA<AppException>().having(
            (excepcion) => excepcion.sesionVencida,
            'sesión vencida',
            true,
          ),
        ),
      );
      cliente.respuestas.add(StubResponse(503, '<html>No disponible</html>'));
      await expectLater(
        api.entregarPedido('1'),
        throwsA(
          isA<AppException>().having(
            (excepcion) => excepcion.rechazoDefinitivo,
            'resultado incierto',
            false,
          ),
        ),
      );
      cliente.respuestas.add(
        StubResponse(200, '<html>Respuesta incorrecta</html>'),
      );
      await expectLater(api.entregarPedido('1'), throwsA(isA<AppException>()));
    },
  );

  test('Envia token, identidad idempotente y cantidades sin confiar precios al cliente', () async {
    final cliente = StubClient();
    final api = ApiRepository(
      urlBase: 'https://chifa.test/api/v1/',
      cliente: cliente,
    );
    addTearDown(api.dispose);
    cliente.responder({
      'token': 'example-token',
      'user': {'id': 1, 'name': 'Mozo', 'username': 'mozo'},
    });
    await api.iniciarSesion('mozo', 'secreto');
    final detalle = const OrderLine(
      idProducto: '9',
      nombre: 'Chaufa',
      precioCentimos: 1800,
      cantidad: 2,
      observaciones: 'Sin cebolla',
    );
    cliente.responder(
      ServiceOrder(
        id: '10',
        idMesa: '1',
        numeroMesa: 1,
        idMozo: '1',
        fechaCreacion: DateTime.utc(2026, 11, 1),
        detalles: [detalle],
      ).toJson(),
    );
    final pedido = await api.enviarPedido(
      OrderDraft(idMesa: '1', clave: 'stable-key', detalles: [detalle]),
    );
    final solicitud = cliente.solicitudes.last;
    expect(solicitud.uri.toString(), 'https://chifa.test/api/v1/orders');
    expect(solicitud.headers.valores['authorization'], 'Bearer example-token');
    expect(solicitud.headers.valores['Idempotency-Key'], 'stable-key');
    final cuerpo = jsonDecode(solicitud.cuerpo.toString()) as Map;
    expect(cuerpo, {
      'table_id': '1',
      'items': [
        {'product_id': '9', 'quantity': 2, 'notes': 'Sin cebolla'},
      ],
    });
    expect(pedido.totalCentimos, 3600);
    cliente.responder(null, estado: 204);
    await api.cerrarMesa('1', ['10']);
    expect(jsonDecode(cliente.solicitudes.last.cuerpo.toString()), {
      'order_ids': ['10'],
    });
  });

  test(
    'Distingue rechazo definitivo de resultado incierto y rechaza HTTP',
    () async {
      final cliente = StubClient();
      final api = ApiRepository(
        urlBase: 'https://chifa.test/api/v1',
        cliente: cliente,
      );
      addTearDown(api.dispose);
      cliente.respuestas.add(
        StubResponse(422, '{"message":"Mesa no asignada"}'),
      );
      await expectLater(
        api.entregarPedido('1'),
        throwsA(
          isA<AppException>()
              .having(
                (excepcion) => excepcion.rechazoDefinitivo,
                'definitivo',
                true,
              )
              .having(
                (excepcion) => excepcion.mensaje,
                'mensaje',
                'Mesa no asignada',
              ),
        ),
      );
      cliente.respuestas.add(StubResponse(503, '{"message":"Intenta luego"}'));
      await expectLater(
        api.entregarPedido('1'),
        throwsA(
          isA<AppException>().having(
            (excepcion) => excepcion.rechazoDefinitivo,
            'incierto',
            false,
          ),
        ),
      );
      cliente.respuestas.add(StubResponse(401, '{"message":"Unauthorized"}'));
      await expectLater(
        api.entregarPedido('1'),
        throwsA(
          isA<AppException>().having(
            (excepcion) => excepcion.sesionVencida,
            'sesion vencida',
            true,
          ),
        ),
      );
      final repositorioInseguro = ApiRepository(
        urlBase: 'http://chifa.test/api',
        cliente: cliente,
      );
      await expectLater(
        repositorioInseguro.iniciarSesion('user', 'pass'),
        throwsA(isA<AppException>()),
      );
      repositorioInseguro.dispose();
    },
  );
}
