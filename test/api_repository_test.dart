import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_chifacentro/src/data/api_repository.dart';
import 'package:proyecto_chifacentro/src/domain/models.dart';

class StubHeaders implements HttpHeaders {
  final Map<String, Object> values = {};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = value;
  }

  @override
  set contentType(ContentType? value) {
    values['content-type'] = '$value';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubResponse extends Stream<List<int>> implements HttpClientResponse {
  StubResponse(this.statusCode, this.body);
  @override
  final int statusCode;
  final String body;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(utf8.encode(body)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubRequest implements HttpClientRequest {
  StubRequest(this.method, this.uri, this.response);
  @override
  final String method;
  @override
  final Uri uri;
  final StubResponse response;
  final body = StringBuffer();
  @override
  final StubHeaders headers = StubHeaders();
  @override
  void write(Object? object) => body.write(object);
  @override
  Future<HttpClientResponse> close() async => response;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubClient implements HttpClient {
  final List<StubResponse> responses = [];
  final List<StubRequest> requests = [];
  void respond(Object? data, {int status = 200}) =>
      responses.add(StubResponse(status, jsonEncode({'data': data})));
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = StubRequest(method, url, responses.removeAt(0));
    requests.add(request);
    return request;
  }

  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Envia token, identidad idempotente y cantidades sin confiar precios al cliente', () async {
    final client = StubClient();
    final api = ApiRepository(
      baseUrl: 'https://chifa.test/api/v1/',
      client: client,
    );
    addTearDown(api.dispose);
    client.respond({
      'token': 'example-token',
      'user': {'id': 1, 'name': 'Mozo', 'username': 'mozo'},
    });
    await api.login('mozo', 'secreto');
    final line = const OrderLine(
      productId: '9',
      name: 'Chaufa',
      priceCents: 1800,
      quantity: 2,
      notes: 'Sin cebolla',
    );
    client.respond(
      ServiceOrder(
        id: '10',
        tableId: '1',
        tableNumber: 1,
        waiterId: '1',
        createdAt: DateTime.utc(2026, 11, 1),
        lines: [line],
      ).toJson(),
    );
    final order = await api.sendOrder(
      OrderDraft(tableId: '1', key: 'stable-key', lines: [line]),
    );
    final request = client.requests.last;
    expect(request.uri.toString(), 'https://chifa.test/api/v1/orders');
    expect(request.headers.values['authorization'], 'Bearer example-token');
    expect(request.headers.values['Idempotency-Key'], 'stable-key');
    final body = jsonDecode(request.body.toString()) as Map;
    expect(body, {
      'table_id': '1',
      'items': [
        {'product_id': '9', 'quantity': 2, 'notes': 'Sin cebolla'},
      ],
    });
    expect(order.totalCents, 3600);
    client.respond(null, status: 204);
    await api.closeTable('1', ['10']);
    expect(jsonDecode(client.requests.last.body.toString()), {
      'order_ids': ['10'],
    });
  });

  test(
    'Distingue rechazo definitivo de resultado incierto y rechaza HTTP',
    () async {
      final client = StubClient();
      final api = ApiRepository(
        baseUrl: 'https://chifa.test/api/v1',
        client: client,
      );
      addTearDown(api.dispose);
      client.responses.add(StubResponse(422, '{"message":"Mesa no asignada"}'));
      await expectLater(
        api.deliverOrder('1'),
        throwsA(
          isA<AppException>()
              .having((e) => e.definitive, 'definitivo', true)
              .having((e) => e.message, 'mensaje', 'Mesa no asignada'),
        ),
      );
      client.responses.add(StubResponse(503, '{"message":"Intenta luego"}'));
      await expectLater(
        api.deliverOrder('1'),
        throwsA(
          isA<AppException>().having((e) => e.definitive, 'incierto', false),
        ),
      );
      client.responses.add(StubResponse(401, '{"message":"Unauthorized"}'));
      await expectLater(
        api.deliverOrder('1'),
        throwsA(
          isA<AppException>().having(
            (e) => e.unauthorized,
            'sesion vencida',
            true,
          ),
        ),
      );
      final insecure = ApiRepository(
        baseUrl: 'http://chifa.test/api',
        client: client,
      );
      await expectLater(
        insecure.login('user', 'pass'),
        throwsA(isA<AppException>()),
      );
      insecure.dispose();
    },
  );
}
