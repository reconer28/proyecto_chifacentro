import 'package:flutter/services.dart';

abstract interface class LocalStore {
  Future<String?> leer(String clave);
  Future<void> guardar(String clave, String valor);
}

/// Almacenamiento privado de Android para borradores y datos de prueba; no guarda credenciales.
class AndroidLocalStore implements LocalStore {
  const AndroidLocalStore();
  static const _canal = MethodChannel('chifa_centro/local_store');
  @override
  Future<String?> leer(String clave) =>
      _canal.invokeMethod<String>('read', {'key': clave});
  @override
  Future<void> guardar(String clave, String valor) =>
      _canal.invokeMethod<void>('write', {'key': clave, 'value': valor});
}

class MemoryStore implements LocalStore {
  final Map<String, String> valores = {};
  @override
  Future<String?> leer(String clave) async => valores[clave];
  @override
  Future<void> guardar(String clave, String valor) async {
    valores[clave] = valor;
  }
}
