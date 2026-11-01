package com.example.proyecto_chifacentro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferences = getSharedPreferences("chifa_centro", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "chifa_centro/local_store")
            .setMethodCallHandler { call, result ->
                val key = call.argument<String>("key")
                if (key == null) {
                    result.error("INVALID_KEY", "Falta la clave de almacenamiento", null)
                } else when (call.method) {
                    "read" -> result.success(preferences.getString(key, null))
                    "write" -> {
                        val value = call.argument<String>("value")
                        if (value == null) result.error("INVALID_VALUE", "Falta el valor", null)
                        else if (preferences.edit().putString(key, value).commit()) result.success(null)
                        else result.error("WRITE_FAILED", "No se pudo guardar el borrador", null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
