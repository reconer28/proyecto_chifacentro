package com.example.proyecto_chifacentro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferencias = getSharedPreferences("chifa_centro", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "chifa_centro/local_store")
            .setMethodCallHandler { llamada, resultado ->
                val clave = llamada.argument<String>("key")
                if (clave == null) {
                    resultado.error("INVALID_KEY", "Falta la clave de almacenamiento", null)
                } else when (llamada.method) {
                    "read" -> resultado.success(preferencias.getString(clave, null))
                    "write" -> {
                        val valor = llamada.argument<String>("value")
                        if (valor == null) resultado.error("INVALID_VALUE", "Falta el valor", null)
                        else if (preferencias.edit().putString(clave, valor).commit()) resultado.success(null)
                        else resultado.error("WRITE_FAILED", "No se pudo guardar el borrador", null)
                    }
                    else -> resultado.notImplemented()
                }
            }
    }
}
