import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/repository.dart';
import '../domain/models.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.repository,
    required this.store,
    this.namespace = 'demo',
  });
  final RestaurantRepository repository;
  final LocalStore store;
  final String namespace;
  Waiter? user;
  List<DiningTable> tables = [];
  List<MenuProduct> products = [];
  List<ServiceOrder> orders = [];
  final Map<String, OrderDraft> drafts = {};
  bool busy = false;
  String? error;
  DateTime? lastUpdated;
  Future<void> _writes = Future.value();
  bool get isDemo => repository.isDemo;
  List<DiningTable> get myTables =>
      tables.where((t) => t.waiterId == user?.id).toList();
  List<ServiceOrder> get myOrders =>
      orders.where((o) => o.waiterId == user?.id).toList();
  OrderDraft? draftFor(String tableId) => drafts[tableId];
  String get _draftKey => 'drafts.v1.$namespace.${user!.id}';
  String _key() =>
      '${DateTime.now().microsecondsSinceEpoch}-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  String _message(Object e) => e is AppException
      ? e.message
      : 'No se pudo completar la operación. Reintenta; tus pedidos se conservarán.';
  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> _persist() {
    final key = _draftKey;
    final value = jsonEncode(drafts.values.map((d) => d.toJson()).toList());
    final next = _writes.then((_) => store.write(key, value));
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> _loadSnapshot() async {
    final data = await repository.load();
    tables = data.tables;
    products = data.products;
    orders = data.orders;
    lastUpdated = DateTime.now();
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (busy) {
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      error = _message(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) => _run(() async {
    final authenticated = await repository.login(username.trim(), password);
    user = authenticated;
    try {
      final raw = await store.read(_draftKey);
      drafts.clear();
      if (raw != null) {
        for (final item in jsonDecode(raw) as List) {
          final d = OrderDraft.fromJson(Map<String, dynamic>.from(item as Map));
          drafts[d.tableId] = d;
        }
      }
      await _loadSnapshot();
    } catch (e) {
      // Keep the authenticated session so a failed initial download is retryable.
      error = _message(e);
    }
  });
  Future<bool> refresh() => _run(_loadSnapshot);
  Future<void> logout() async {
    if (busy) {
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _persist();
    } catch (e) {
      error =
          'No se pudieron guardar los borradores. Reintenta antes de salir.';
      busy = false;
      notifyListeners();
      return;
    }
    try {
      await repository.logout();
    } catch (_) {
      /* Local token is cleared by the repository. */
    }
    user = null;
    drafts.clear();
    tables = [];
    products = [];
    orders = [];
    lastUpdated = null;
    busy = false;
    notifyListeners();
  }

  void _validateTable(String tableId) {
    if (!myTables.any((t) => t.id == tableId)) {
      throw const AppException(
        'La mesa ya no está asignada a tu usuario. Actualiza tus mesas.',
        definitive: true,
      );
    }
  }

  Future<bool> changeLine(
    String tableId,
    MenuProduct product, {
    int delta = 0,
    String? notes,
  }) => _run(() async {
    _validateTable(tableId);
    final d = drafts.putIfAbsent(
      tableId,
      () => OrderDraft(tableId: tableId, key: _key()),
    );
    if (d.pending) {
      throw const AppException(
        'Confirma el envío pendiente antes de editar el pedido.',
      );
    }
    if (!product.available && delta > 0) {
      throw const AppException('Este plato no está disponible.');
    }
    final i = d.lines.indexWhere((l) => l.productId == product.id);
    if (i < 0) {
      if (delta > 0) {
        d.lines.add(
          OrderLine(
            productId: product.id,
            name: product.name,
            priceCents: product.priceCents,
            quantity: delta,
            notes: notes?.trim() ?? '',
          ),
        );
      }
    } else {
      final old = d.lines[i];
      final quantity = old.quantity + delta;
      if (quantity > 99) {
        throw const AppException('El máximo por plato es 99 unidades.');
      }
      if (quantity <= 0) {
        d.lines.removeAt(i);
      } else {
        d.lines[i] = old.update(quantity: quantity, notes: notes?.trim());
      }
    }
    if (d.lines.isEmpty) {
      drafts.remove(tableId);
    }
    await _persist();
  });
  Future<bool> discardDraft(String tableId) => _run(() async {
    if (drafts[tableId]?.pending ?? false) {
      throw const AppException(
        'Primero confirma el envío pendiente con el servidor.',
      );
    }
    drafts.remove(tableId);
    await _persist();
  });
  Future<bool> assignTables(List<String> ids, String password) =>
      _run(() async {
        if (drafts.values.any(
          (d) =>
              d.lines.isNotEmpty &&
              myTables.any((t) => t.id == d.tableId) &&
              !ids.contains(d.tableId),
        )) {
          throw const AppException(
            'Envía o descarta los borradores antes de quitar sus mesas.',
          );
        }
        await repository.assignTables(ids, password);
        await _refreshAfterMutation();
      });
  Future<void> _refreshAfterMutation() async {
    try {
      await _loadSnapshot();
    } catch (e) {
      error =
          'La operación se confirmó. No pudimos actualizar la vista: ${_message(e)}';
    }
  }

  Future<bool> sendOrder(String tableId) => _run(() async {
    final d = drafts[tableId];
    if (d == null || d.lines.isEmpty) {
      throw const AppException('Agrega platos a tu pedido.');
    }
    // A receipt must remain recoverable even if the table was reassigned.
    // For pending requests the server checks idempotency before ownership.
    if (!d.pending) {
      _validateTable(tableId);
    }
    d.pending = true;
    // Persist the exact request identity before any network write.
    await _persist();
    ServiceOrder order;
    try {
      order = await repository.sendOrder(d);
    } on AppException catch (e) {
      if (e.definitive) {
        drafts[tableId] = OrderDraft(
          tableId: tableId,
          key: _key(),
          lines: List.of(d.lines),
        );
        await _persist();
      }
      rethrow;
    }
    drafts.remove(tableId);
    orders = [order, ...orders.where((o) => o.id != order.id)];
    try {
      await _persist();
    } catch (_) {
      error = 'Pedido confirmado. No se pudo limpiar la copia local; un reintento conservará su identificador.';
    }
    await _refreshAfterMutation();
  });
  Future<bool> cancelOrder(String id, String reason, String password) =>
      _run(() async {
        await repository.cancelOrder(id, reason, password);
        await _refreshAfterMutation();
      });
  Future<bool> deliverOrder(String id) => _run(() async {
    await repository.deliverOrder(id);
    await _refreshAfterMutation();
  });
  Future<bool> closeTable(String tableId) => _run(() async {
    if (drafts[tableId]?.lines.isNotEmpty ?? false) {
      throw const AppException(
        'Envía o descarta el borrador antes de cerrar la mesa.',
      );
    }
    final ids = myOrders
        .where((o) => o.tableId == tableId && o.closedAt == null)
        .map((o) => o.id)
        .toList();
    await repository.closeTable(tableId, ids);
    await _refreshAfterMutation();
  });
  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
