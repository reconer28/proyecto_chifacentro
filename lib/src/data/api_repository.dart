import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/models.dart';
import 'repository.dart';

/// The proposed Laravel contract is documented in docs/API_CONTRACT.md.
class ApiRepository implements RestaurantRepository {
  ApiRepository({required this.baseUrl, HttpClient? client})
    : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
  }
  final String baseUrl;
  final HttpClient _client;
  String? _token;
  @override
  bool get isDemo => false;
  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const AppException(
        'Configura API_BASE_URL con la URL HTTPS de Laravel, terminada en /api/v1.',
        definitive: true,
      );
    }
    HttpClientRequest? request;
    try {
      return await (() async {
        request = await _client.openUrl(
          method,
          Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path'),
        );
        request!.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (_token != null) {
          request!.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $_token',
          );
        }
        if (idempotencyKey != null) {
          request!.headers.set('Idempotency-Key', idempotencyKey);
        }
        if (body != null) {
          request!.headers.contentType = ContentType.json;
          request!.write(jsonEncode(body));
        }
        final response = await request!.close();
        final raw = await response.transform(utf8.decoder).join();
        dynamic payload;
        try {
          payload = raw.isEmpty ? null : jsonDecode(raw);
        } on FormatException {
          throw const AppException(
            'El servidor no devolvió una respuesta JSON válida.',
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final status = response.statusCode;
          throw AppException(
            status == 401
                ? 'Tu sesión venció. Vuelve a iniciar sesión; tus borradores están guardados.'
                : payload is Map && payload['message'] is String
                ? payload['message'] as String
                : 'No se pudo completar la operación ($status).',
            unauthorized: status == 401,
            definitive: [400, 401, 403, 404, 422].contains(status),
          );
        }
        return payload is Map ? payload['data'] : null;
      })().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      request?.abort();
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

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
  @override
  Future<Waiter> login(String username, String password) async {
    final j = _map(
      await _request(
        'POST',
        '/auth/login',
        body: {
          'username': username,
          'password': password,
          'device_name': 'Chifa Centro Android',
        },
      ),
    );
    final user = Waiter.fromJson(_map(j['user']));
    _token = j['token'] as String;
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _request('POST', '/auth/logout');
    } finally {
      _token = null;
    }
  }

  @override
  Future<RestaurantSnapshot> load() async {
    final values = await Future.wait([
      _request('GET', '/tables'),
      _request('GET', '/menu'),
      _request('GET', '/orders'),
    ]);
    return RestaurantSnapshot(
      tables: (values[0] as List)
          .map((v) => DiningTable.fromJson(_map(v)))
          .toList(),
      products: (values[1] as List)
          .map((v) => MenuProduct.fromJson(_map(v)))
          .toList(),
      orders: (values[2] as List)
          .map((v) => ServiceOrder.fromJson(_map(v)))
          .toList(),
    );
  }

  @override
  Future<void> assignTables(List<String> tableIds, String adminPassword) async {
    await _request(
      'PUT',
      '/me/tables',
      body: {'table_ids': tableIds, 'admin_password': adminPassword},
    );
  }

  @override
  Future<ServiceOrder> sendOrder(OrderDraft draft) async =>
      ServiceOrder.fromJson(
        _map(
          await _request(
            'POST',
            '/orders',
            idempotencyKey: draft.key,
            body: {
              'table_id': draft.tableId,
              'items': draft.lines
                  .map(
                    (l) => {
                      'product_id': l.productId,
                      'quantity': l.quantity,
                      'notes': l.notes,
                    },
                  )
                  .toList(),
            },
          ),
        ),
      );
  @override
  Future<void> cancelOrder(
    String orderId,
    String reason,
    String adminPassword,
  ) async {
    await _request(
      'POST',
      '/orders/${Uri.encodeComponent(orderId)}/cancel',
      body: {'reason': reason, 'admin_password': adminPassword},
    );
  }

  @override
  Future<void> deliverOrder(String orderId) async {
    await _request('POST', '/orders/${Uri.encodeComponent(orderId)}/deliver');
  }

  @override
  Future<void> closeTable(String tableId, List<String> expectedOrderIds) async {
    await _request(
      'POST',
      '/tables/${Uri.encodeComponent(tableId)}/close',
      body: {'order_ids': expectedOrderIds},
    );
  }

  @override
  void dispose() => _client.close(force: true);
}
