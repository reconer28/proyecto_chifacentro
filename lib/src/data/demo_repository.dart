import 'dart:convert';

import '../domain/models.dart';
import 'local_store.dart';
import 'repository.dart';

class DemoRepository implements RestaurantRepository {
  DemoRepository({
    required this.store,
    this.delay = const Duration(milliseconds: 280),
  });
  final LocalStore store;
  final Duration delay;
  bool offline = false;
  Waiter? _user;
  bool _loaded = false;
  List<DiningTable> _tables = List.generate(
    12,
    (i) => DiningTable(
      id: '${i + 1}',
      number: i + 1,
      seats: i % 3 == 0 ? 6 : 4,
      zone: i < 8 ? 'Salón principal' : 'Terraza',
      waiterId: i < 4 ? '1' : (i == 4 || i == 5 ? '2' : null),
    ),
  );
  List<ServiceOrder> _orders = [];
  final Map<String, String> _receipts = {};
  static const products = [
    MenuProduct(
      id: '1',
      name: 'Arroz chaufa de pollo',
      description: 'Arroz al wok, pollo, huevo y cebollita china.',
      category: 'Chaufas',
      priceCents: 1800,
      featured: true,
    ),
    MenuProduct(
      id: '2',
      name: 'Chaufa especial',
      description: 'Pollo, cerdo y langostinos al fuego del wok.',
      category: 'Chaufas',
      priceCents: 2500,
      featured: true,
    ),
    MenuProduct(
      id: '3',
      name: 'Chaufa de verduras',
      description: 'Verduras frescas, huevo y nuestro toque de sillao.',
      category: 'Chaufas',
      priceCents: 1600,
    ),
    MenuProduct(
      id: '4',
      name: 'Tallarín saltado de pollo',
      description: 'Fideos, verduras crocantes y pollo salteado.',
      category: 'Tallarines',
      priceCents: 2000,
    ),
    MenuProduct(
      id: '5',
      name: 'Aeropuerto',
      description: 'El encuentro del chaufa y el tallarín, con pollo.',
      category: 'Especiales',
      priceCents: 2300,
      featured: true,
    ),
    MenuProduct(
      id: '6',
      name: 'Pollo tipakay',
      description: 'Pollo crocante bañado en salsa de tamarindo.',
      category: 'Especiales',
      priceCents: 2400,
    ),
    MenuProduct(
      id: '7',
      name: 'Wantán frito',
      description: 'Seis unidades crocantes con salsa de tamarindo.',
      category: 'Entradas',
      priceCents: 1200,
    ),
    MenuProduct(
      id: '8',
      name: 'Sopa wantán',
      description: 'Caldo de la casa, wantanes, pollo y verduras.',
      category: 'Entradas',
      priceCents: 1400,
    ),
    MenuProduct(
      id: '9',
      name: 'Inca Kola 500 ml',
      description: 'Bien helada, para acompañar tu pedido.',
      category: 'Bebidas',
      priceCents: 500,
    ),
    MenuProduct(
      id: '10',
      name: 'Chicha morada',
      description: 'Un vaso de nuestra chicha de la casa.',
      category: 'Bebidas',
      priceCents: 600,
    ),
    MenuProduct(
      id: '11',
      name: 'Tallarín de langostinos',
      description: 'Langostinos salteados con verduras de estación.',
      category: 'Tallarines',
      priceCents: 2800,
      available: false,
    ),
  ];
  @override
  bool get isDemo => true;
  Future<void> _check() async {
    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (offline) {
      throw const AppException(
        'Sin conexión de prueba. Tu borrador está guardado; vuelve a conectar desde Mi cuenta.',
      );
    }
    if (_user == null) {
      throw const AppException(
        'Inicia sesión para continuar.',
        unauthorized: true,
        definitive: true,
      );
    }
  }

  @override
  Future<Waiter> login(String username, String password) async {
    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (!['mozo', 'lucia'].contains(username) || password != '123456') {
      throw const AppException(
        'Usuario o contraseña incorrectos.',
        definitive: true,
      );
    }
    _user = Waiter(
      id: username == 'mozo' ? '1' : '2',
      name: username == 'mozo' ? 'Diego Ramírez' : 'Lucía Torres',
      username: username,
    );
    return _user!;
  }

  Future<void> _save() => store.write(
    'demo.v1',
    jsonEncode({
      'tables': _tables.map((t) => t.toJson()).toList(),
      'orders': _orders.map((o) => o.toJson()).toList(),
      'receipts': _receipts,
    }),
  );
  @override
  Future<RestaurantSnapshot> load() async {
    await _check();
    if (!_loaded) {
      final raw = await store.read('demo.v1');
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _tables = (j['tables'] as List)
            .map(
              (v) => DiningTable.fromJson(Map<String, dynamic>.from(v as Map)),
            )
            .toList();
        _orders = (j['orders'] as List)
            .map(
              (v) => ServiceOrder.fromJson(Map<String, dynamic>.from(v as Map)),
            )
            .toList();
        _receipts.addAll(Map<String, String>.from(j['receipts'] as Map));
      }
      _loaded = true;
    }
    return RestaurantSnapshot(
      tables: List.of(_tables),
      products: products,
      orders: _orders
          .where((o) => o.waiterId == _user!.id)
          .toList()
          .reversed
          .toList(),
    );
  }

  void _admin(String password) {
    if (password != '2468') {
      throw const AppException(
        'La clave del administrador es incorrecta.',
        definitive: true,
      );
    }
  }

  DiningTable _ownTable(String id) {
    final table = _tables.firstWhere((t) => t.id == id);
    if (table.waiterId != _user!.id) {
      throw const AppException(
        'Esta mesa no está asignada a tu usuario.',
        definitive: true,
      );
    }
    return table;
  }

  @override
  Future<void> assignTables(List<String> tableIds, String adminPassword) async {
    await _check();
    _admin(adminPassword);
    for (final t in _tables) {
      if (tableIds.contains(t.id) &&
          t.waiterId != null &&
          t.waiterId != _user!.id) {
        throw const AppException(
          'Una mesa ya está asignada a otro mozo.',
          definitive: true,
        );
      }
      if (t.waiterId == _user!.id && t.occupied && !tableIds.contains(t.id)) {
        throw const AppException(
          'Cierra la atención antes de quitar una mesa ocupada.',
          definitive: true,
        );
      }
    }
    _tables = _tables
        .map(
          (t) => tableIds.contains(t.id)
              ? t.update(waiterId: _user!.id)
              : (t.waiterId == _user!.id ? t.update(clearWaiter: true) : t),
        )
        .toList();
    await _save();
  }

  @override
  Future<ServiceOrder> sendOrder(OrderDraft draft) async {
    await _check();
    final receipt = _receipts[draft.key];
    if (receipt != null) {
      return _orders.firstWhere((o) => o.id == receipt);
    }
    final table = _ownTable(draft.tableId);
    if (draft.lines.isEmpty) {
      throw const AppException('Agrega al menos un plato.', definitive: true);
    }
    final lines = draft.lines.map((line) {
      final product = products.firstWhere((p) => p.id == line.productId);
      if (!product.available || line.quantity < 1 || line.quantity > 99) {
        throw const AppException(
          'Revisa la disponibilidad y las cantidades.',
          definitive: true,
        );
      }
      return OrderLine(
        productId: product.id,
        name: product.name,
        priceCents: product.priceCents,
        quantity: line.quantity,
        notes: line.notes,
      );
    }).toList();
    final order = ServiceOrder(
      id: '${1001 + _orders.length}',
      tableId: table.id,
      tableNumber: table.number,
      waiterId: _user!.id,
      createdAt: DateTime.now(),
      lines: lines,
    );
    _orders.add(order);
    _receipts[draft.key] = order.id;
    _recalculate();
    await _save();
    return order;
  }

  void _recalculate() {
    _tables = _tables.map((t) {
      final active = _orders.where(
        (o) =>
            o.tableId == t.id &&
            o.closedAt == null &&
            o.status != OrderStatus.cancelled,
      );
      return t.update(
        occupied: active.isNotEmpty,
        totalCents: active.fold(0, (sum, o) => sum! + o.totalCents),
      );
    }).toList();
  }

  ServiceOrder _ownOrder(String id) {
    final order = _orders.firstWhere((o) => o.id == id);
    _ownTable(order.tableId);
    if (order.closedAt != null || order.status == OrderStatus.cancelled) {
      throw const AppException(
        'El pedido ya está cerrado o anulado.',
        definitive: true,
      );
    }
    return order;
  }

  @override
  Future<void> cancelOrder(
    String orderId,
    String reason,
    String adminPassword,
  ) async {
    await _check();
    _admin(adminPassword);
    final order = _ownOrder(orderId);
    if (order.status != OrderStatus.sent || reason.trim().isEmpty) {
      throw const AppException(
        'Solo puedes anular pedidos enviados indicando un motivo.',
        definitive: true,
      );
    }
    _orders[_orders.indexOf(order)] = order.update(
      status: OrderStatus.cancelled,
      cancellationReason: reason.trim(),
    );
    _recalculate();
    await _save();
  }

  @override
  Future<void> deliverOrder(String orderId) async {
    await _check();
    final order = _ownOrder(orderId);
    _orders[_orders.indexOf(order)] = order.update(
      status: OrderStatus.delivered,
    );
    await _save();
  }

  @override
  Future<void> closeTable(String tableId, List<String> expectedOrderIds) async {
    await _check();
    _ownTable(tableId);
    final expected = _orders
        .where((o) => expectedOrderIds.contains(o.id) && o.tableId == tableId)
        .toList();
    if (expectedOrderIds.isEmpty ||
        expected.length != expectedOrderIds.length) {
      throw const AppException(
        'Actualiza los pedidos de la mesa antes de cerrarla.',
        definitive: true,
      );
    }
    if (expected.every((o) => o.closedAt != null)) {
      return;
    }
    final currentIds = _orders
        .where((o) => o.tableId == tableId && o.closedAt == null)
        .map((o) => o.id)
        .toSet();
    if (currentIds.length != expectedOrderIds.length ||
        !currentIds.containsAll(expectedOrderIds)) {
      throw const AppException(
        'Los pedidos cambiaron. Actualiza la mesa antes de cerrarla.',
        definitive: true,
      );
    }
    if (_orders.any(
      (o) =>
          o.tableId == tableId &&
          o.closedAt == null &&
          o.status != OrderStatus.cancelled &&
          o.status != OrderStatus.delivered,
    )) {
      throw const AppException(
        'Marca los pedidos como entregados antes de cerrar la mesa.',
        definitive: true,
      );
    }
    _orders = _orders
        .map(
          (o) => o.tableId == tableId && o.closedAt == null
              ? o.update(closedAt: DateTime.now())
              : o,
        )
        .toList();
    _recalculate();
    await _save();
  }

  @override
  Future<void> logout() async {
    _user = null;
    offline = false;
  }

  @override
  void dispose() {}
}
