String formatearImporte(int centimos) =>
    'S/ ${(centimos / 100).toStringAsFixed(2)}';

class AppException implements Exception {
  const AppException(
    this.mensaje, {
    this.sesionVencida = false,
    this.rechazoDefinitivo = false,
  });
  final String mensaje;
  final bool sesionVencida;
  final bool rechazoDefinitivo;
  @override
  String toString() => mensaje;
}

class Waiter {
  const Waiter({
    required this.id,
    required this.nombre,
    required this.nombreUsuario,
  });
  final String id;
  final String nombre;
  final String nombreUsuario;
  factory Waiter.fromJson(Map<String, dynamic> datosJson) => Waiter(
    id: '${datosJson['id']}',
    nombre: datosJson['name'] as String,
    nombreUsuario: datosJson['username'] as String,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': nombre,
    'username': nombreUsuario,
  };
}

class DiningTable {
  const DiningTable({
    required this.id,
    required this.numero,
    required this.capacidad,
    required this.zona,
    this.idMozo,
    this.ocupada = false,
    this.totalCentimos = 0,
  });
  final String id;
  final int numero;
  final int capacidad;
  final String zona;
  final String? idMozo;
  final bool ocupada;
  final int totalCentimos;
  factory DiningTable.fromJson(Map<String, dynamic> datosJson) => DiningTable(
    id: '${datosJson['id']}',
    numero: datosJson['number'] as int,
    capacidad: datosJson['seats'] as int,
    zona: datosJson['zone'] as String,
    idMozo: datosJson['waiter_id']?.toString(),
    ocupada: datosJson['occupied'] as bool,
    totalCentimos: datosJson['total_cents'] as int,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': numero,
    'seats': capacidad,
    'zone': zona,
    'waiter_id': idMozo,
    'occupied': ocupada,
    'total_cents': totalCentimos,
  };
  DiningTable actualizar({
    String? idMozo,
    bool? ocupada,
    int? totalCentimos,
    bool quitarMozo = false,
  }) => DiningTable(
    id: id,
    numero: numero,
    capacidad: capacidad,
    zona: zona,
    idMozo: quitarMozo ? null : idMozo ?? this.idMozo,
    ocupada: ocupada ?? this.ocupada,
    totalCentimos: totalCentimos ?? this.totalCentimos,
  );
}

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.precioCentimos,
    this.disponible = true,
    this.destacado = false,
  });
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int precioCentimos;
  final bool disponible;
  final bool destacado;
  factory MenuProduct.fromJson(Map<String, dynamic> datosJson) => MenuProduct(
    id: '${datosJson['id']}',
    nombre: datosJson['name'] as String,
    descripcion: datosJson['description'] as String,
    categoria: datosJson['category'] as String,
    precioCentimos: datosJson['price_cents'] as int,
    disponible: datosJson['available'] as bool,
    destacado: datosJson['featured'] as bool? ?? false,
  );
}

class OrderLine {
  const OrderLine({
    required this.idProducto,
    required this.nombre,
    required this.precioCentimos,
    this.cantidad = 1,
    this.observaciones = '',
  });
  final String idProducto;
  final String nombre;
  final int precioCentimos;
  final int cantidad;
  final String observaciones;
  int get totalCentimos => precioCentimos * cantidad;
  OrderLine actualizar({int? cantidad, String? observaciones}) => OrderLine(
    idProducto: idProducto,
    nombre: nombre,
    precioCentimos: precioCentimos,
    cantidad: cantidad ?? this.cantidad,
    observaciones: observaciones ?? this.observaciones,
  );
  Map<String, dynamic> toJson() => {
    'product_id': idProducto,
    'name': nombre,
    'price_cents': precioCentimos,
    'quantity': cantidad,
    'notes': observaciones,
  };
  factory OrderLine.fromJson(Map<String, dynamic> datosJson) => OrderLine(
    idProducto: '${datosJson['product_id']}',
    nombre: datosJson['name'] as String,
    precioCentimos: datosJson['price_cents'] as int,
    cantidad: datosJson['quantity'] as int,
    observaciones: datosJson['notes'] as String? ?? '',
  );
}

class OrderDraft {
  OrderDraft({
    required this.idMesa,
    required this.clave,
    List<OrderLine>? detalles,
    this.pendiente = false,
  }) : detalles = detalles ?? [];
  final String idMesa;
  final String clave;
  final List<OrderLine> detalles;
  bool pendiente;
  int get totalCentimos =>
      detalles.fold(0, (suma, detalle) => suma + detalle.totalCentimos);
  int get cantidad =>
      detalles.fold(0, (suma, detalle) => suma + detalle.cantidad);
  Map<String, dynamic> toJson() => {
    'table_id': idMesa,
    'key': clave,
    'pending': pendiente,
    'lines': detalles.map((detalleActual) => detalleActual.toJson()).toList(),
  };
  factory OrderDraft.fromJson(Map<String, dynamic> datosJson) => OrderDraft(
    idMesa: '${datosJson['table_id']}',
    clave: datosJson['key'] as String,
    pendiente: datosJson['pending'] as bool? ?? false,
    detalles: (datosJson['lines'] as List)
        .map(
          (detalleActual) => OrderLine.fromJson(
            Map<String, dynamic>.from(detalleActual as Map),
          ),
        )
        .toList(),
  );
}

enum OrderStatus {
  sent('Enviado'),
  preparing('En preparación'),
  ready('Listo'),
  delivered('Entregado'),
  cancelled('Anulado');

  const OrderStatus(this.etiqueta);
  final String etiqueta;
}

class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.idMesa,
    required this.numeroMesa,
    required this.idMozo,
    required this.fechaCreacion,
    required this.detalles,
    this.estado = OrderStatus.sent,
    this.fechaCierre,
    this.motivoAnulacion,
  });
  final String id;
  final String idMesa;
  final int numeroMesa;
  final String idMozo;
  final DateTime fechaCreacion;
  final DateTime? fechaCierre;
  final List<OrderLine> detalles;
  final OrderStatus estado;
  final String? motivoAnulacion;
  int get totalCentimos => detalles.fold(
    0,
    (suma, detalleActual) => suma + detalleActual.totalCentimos,
  );
  ServiceOrder actualizar({
    OrderStatus? estado,
    DateTime? fechaCierre,
    String? motivoAnulacion,
  }) => ServiceOrder(
    id: id,
    idMesa: idMesa,
    numeroMesa: numeroMesa,
    idMozo: idMozo,
    fechaCreacion: fechaCreacion,
    detalles: detalles,
    estado: estado ?? this.estado,
    fechaCierre: fechaCierre ?? this.fechaCierre,
    motivoAnulacion: motivoAnulacion ?? this.motivoAnulacion,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'table_id': idMesa,
    'table_number': numeroMesa,
    'waiter_id': idMozo,
    'created_at': fechaCreacion.toIso8601String(),
    'closed_at': fechaCierre?.toIso8601String(),
    'status': estado.name,
    'lines': detalles.map((detalleActual) => detalleActual.toJson()).toList(),
    'cancellation_reason': motivoAnulacion,
  };
  factory ServiceOrder.fromJson(Map<String, dynamic> datosJson) => ServiceOrder(
    id: '${datosJson['id']}',
    idMesa: '${datosJson['table_id']}',
    numeroMesa: datosJson['table_number'] as int,
    idMozo: '${datosJson['waiter_id']}',
    fechaCreacion: DateTime.parse(datosJson['created_at'] as String).toLocal(),
    fechaCierre: datosJson['closed_at'] == null
        ? null
        : DateTime.parse(datosJson['closed_at'] as String).toLocal(),
    estado: OrderStatus.values.byName(datosJson['status'] as String),
    motivoAnulacion: datosJson['cancellation_reason'] as String?,
    detalles: (datosJson['lines'] as List)
        .map(
          (detalleActual) => OrderLine.fromJson(
            Map<String, dynamic>.from(detalleActual as Map),
          ),
        )
        .toList(),
  );
}

class RestaurantSnapshot {
  const RestaurantSnapshot({
    required this.mesas,
    required this.productos,
    required this.pedidos,
  });
  final List<DiningTable> mesas;
  final List<MenuProduct> productos;
  final List<ServiceOrder> pedidos;
}
