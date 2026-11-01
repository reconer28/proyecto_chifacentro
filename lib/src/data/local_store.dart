import 'package:flutter/services.dart';

abstract interface class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Private Android preferences: drafts and demo data, never credentials.
class AndroidLocalStore implements LocalStore {
  const AndroidLocalStore();
  static const _channel = MethodChannel('chifa_centro/local_store');
  @override
  Future<String?> read(String key) =>
      _channel.invokeMethod<String>('read', {'key': key});
  @override
  Future<void> write(String key, String value) =>
      _channel.invokeMethod<void>('write', {'key': key, 'value': value});
}

class MemoryStore implements LocalStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
