String money(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';

class AppException implements Exception {
  const AppException(
    this.message, {
    this.unauthorized = false,
    this.definitive = false,
  });
  final String message;
  final bool unauthorized;
  final bool definitive;
  @override
  String toString() => message;
}

class Waiter {
  const Waiter({required this.id, required this.name, required this.username});
  final String id;
  final String name;
  final String username;
  factory Waiter.fromJson(Map<String, dynamic> j) => Waiter(
    id: '${j['id']}',
    name: j['name'] as String,
    username: j['username'] as String,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
  };
}

class DiningTable {
  const DiningTable({
    required this.id,
    required this.number,
    required this.seats,
    required this.zone,
    this.waiterId,
    this.occupied = false,
    this.totalCents = 0,
  });
  final String id;
  final int number;
  final int seats;
  final String zone;
  final String? waiterId;
  final bool occupied;
  final int totalCents;
  factory DiningTable.fromJson(Map<String, dynamic> j) => DiningTable(
    id: '${j['id']}',
    number: j['number'] as int,
    seats: j['seats'] as int,
    zone: j['zone'] as String,
    waiterId: j['waiter_id']?.toString(),
    occupied: j['occupied'] as bool,
    totalCents: j['total_cents'] as int,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'seats': seats,
    'zone': zone,
    'waiter_id': waiterId,
    'occupied': occupied,
    'total_cents': totalCents,
  };
  DiningTable update({
    String? waiterId,
    bool? occupied,
    int? totalCents,
    bool clearWaiter = false,
  }) => DiningTable(
    id: id,
    number: number,
    seats: seats,
    zone: zone,
    waiterId: clearWaiter ? null : waiterId ?? this.waiterId,
    occupied: occupied ?? this.occupied,
    totalCents: totalCents ?? this.totalCents,
  );
}

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.priceCents,
    this.available = true,
    this.featured = false,
  });
  final String id;
  final String name;
  final String description;
  final String category;
  final int priceCents;
  final bool available;
  final bool featured;
  factory MenuProduct.fromJson(Map<String, dynamic> j) => MenuProduct(
    id: '${j['id']}',
    name: j['name'] as String,
    description: j['description'] as String,
    category: j['category'] as String,
    priceCents: j['price_cents'] as int,
    available: j['available'] as bool,
    featured: j['featured'] as bool? ?? false,
  );
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.priceCents,
    this.quantity = 1,
    this.notes = '',
  });
  final String productId;
  final String name;
  final int priceCents;
  final int quantity;
  final String notes;
  int get totalCents => priceCents * quantity;
  OrderLine update({int? quantity, String? notes}) => OrderLine(
    productId: productId,
    name: name,
    priceCents: priceCents,
    quantity: quantity ?? this.quantity,
    notes: notes ?? this.notes,
  );
  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': name,
    'price_cents': priceCents,
    'quantity': quantity,
    'notes': notes,
  };
  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
    productId: '${j['product_id']}',
    name: j['name'] as String,
    priceCents: j['price_cents'] as int,
    quantity: j['quantity'] as int,
    notes: j['notes'] as String? ?? '',
  );
}

class OrderDraft {
  OrderDraft({
    required this.tableId,
    required this.key,
    List<OrderLine>? lines,
    this.pending = false,
  }) : lines = lines ?? [];
  final String tableId;
  final String key;
  final List<OrderLine> lines;
  bool pending;
  int get totalCents => lines.fold(0, (sum, line) => sum + line.totalCents);
  int get quantity => lines.fold(0, (sum, line) => sum + line.quantity);
  Map<String, dynamic> toJson() => {
    'table_id': tableId,
    'key': key,
    'pending': pending,
    'lines': lines.map((l) => l.toJson()).toList(),
  };
  factory OrderDraft.fromJson(Map<String, dynamic> j) => OrderDraft(
    tableId: '${j['table_id']}',
    key: j['key'] as String,
    pending: j['pending'] as bool? ?? false,
    lines: (j['lines'] as List)
        .map((l) => OrderLine.fromJson(Map<String, dynamic>.from(l as Map)))
        .toList(),
  );
}

enum OrderStatus {
  sent('Enviado'),
  preparing('En preparación'),
  ready('Listo'),
  delivered('Entregado'),
  cancelled('Anulado');

  const OrderStatus(this.label);
  final String label;
}

class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.waiterId,
    required this.createdAt,
    required this.lines,
    this.status = OrderStatus.sent,
    this.closedAt,
    this.cancellationReason,
  });
  final String id;
  final String tableId;
  final int tableNumber;
  final String waiterId;
  final DateTime createdAt;
  final DateTime? closedAt;
  final List<OrderLine> lines;
  final OrderStatus status;
  final String? cancellationReason;
  int get totalCents => lines.fold(0, (sum, l) => sum + l.totalCents);
  ServiceOrder update({
    OrderStatus? status,
    DateTime? closedAt,
    String? cancellationReason,
  }) => ServiceOrder(
    id: id,
    tableId: tableId,
    tableNumber: tableNumber,
    waiterId: waiterId,
    createdAt: createdAt,
    lines: lines,
    status: status ?? this.status,
    closedAt: closedAt ?? this.closedAt,
    cancellationReason: cancellationReason ?? this.cancellationReason,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'table_id': tableId,
    'table_number': tableNumber,
    'waiter_id': waiterId,
    'created_at': createdAt.toIso8601String(),
    'closed_at': closedAt?.toIso8601String(),
    'status': status.name,
    'lines': lines.map((l) => l.toJson()).toList(),
    'cancellation_reason': cancellationReason,
  };
  factory ServiceOrder.fromJson(Map<String, dynamic> j) => ServiceOrder(
    id: '${j['id']}',
    tableId: '${j['table_id']}',
    tableNumber: j['table_number'] as int,
    waiterId: '${j['waiter_id']}',
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    closedAt: j['closed_at'] == null
        ? null
        : DateTime.parse(j['closed_at'] as String).toLocal(),
    status: OrderStatus.values.byName(j['status'] as String),
    cancellationReason: j['cancellation_reason'] as String?,
    lines: (j['lines'] as List)
        .map((l) => OrderLine.fromJson(Map<String, dynamic>.from(l as Map)))
        .toList(),
  );
}

class RestaurantSnapshot {
  const RestaurantSnapshot({
    required this.tables,
    required this.products,
    required this.orders,
  });
  final List<DiningTable> tables;
  final List<MenuProduct> products;
  final List<ServiceOrder> orders;
}
