# Chifa Centro · Pedidos

Frontend Flutter para celulares Android. Permite iniciar sesión como mozo, asignarse mesas con autorización del administrador, tomar pedidos, agregar observaciones, enviar pedidos adicionales, consultar estados, marcar entrega y cerrar la atención de una mesa.

## Ejecutar ahora

Abre este proyecto en VS Code, selecciona un celular o emulador Android y ejecuta:

```powershell
flutter pub get
flutter run
```

La app abre en **modo demostración**, identificado en pantalla. No necesita Laravel.

| Acceso de prueba | Valor |
|---|---|
| Usuario | `mozo` o `lucia` |
| Contraseña | `123456` |
| Clave de administrador | `2468` |

`mozo` tiene inicialmente las mesas 1 a 4; `lucia`, las mesas 5 y 6. Las demás pueden asignarse con la clave. La demo guarda las asignaciones y pedidos en el dispositivo; por eso los cambios se conservan al volver a entrar.

## Flujo de prueba

1. Inicia sesión y entra a una mesa de tu usuario.
2. Agrega platos o bebidas; revisa el pedido y agrega observaciones por producto.
3. Envía el pedido. Puedes volver a la carta y enviar platos adicionales.
4. Abre **Cuenta de mesa**, despliega cada pedido y marca los platos como entregados.
5. Finaliza la atención para liberar la mesa. Su asignación se conserva.
6. En **Asignar**, confirma la selección con la clave del administrador. No se pueden tomar mesas de otro mozo ni quitar mesas con atención o borradores.
7. En **Mi cuenta**, activa la simulación sin conexión. Intenta enviar, desactiva la simulación y reintenta desde el pedido pendiente.

Los borradores se guardan por usuario en almacenamiento privado Android. La app conserva la misma clave en reintentos inciertos y bloquea la edición hasta confirmarlos. El backend real también debe implementar idempotencia.

## Conectar Laravel

```powershell
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://tu-dominio.com/api/v1
```

Consulta [el contrato de API](docs/API_CONTRACT.md): incluye rutas, cuerpos, respuestas JSON, autorización, importes e idempotencia. Cambiar la URL no basta si el backend usa otro formato: se adapta el repositorio y los modelos. El modo real solo acepta HTTPS y no cambia a datos demo ante errores. Los tokens solo viven en memoria.

## Estructura

- `lib/src/presentation/`: pantallas y componentes visuales.
- `lib/src/application/`: estado, borradores y acciones del mozo.
- `lib/src/domain/`: modelos independientes de las pantallas.
- `lib/src/data/`: contrato de repositorio, demo persistente, transporte HTTP real y almacenamiento local.
- `lib/src/core/`: tema y configuración por compilación.
- `android/.../MainActivity.kt`: canal nativo para persistencia privada sin dependencias adicionales.

La carta y las mesas de ejemplo solo existen en `DemoRepository`. El frontend real obtiene cantidades, disponibilidad y precios del backend. El servidor recalcula el total. Los importes se manejan en céntimos para evitar errores de redondeo.

## Validación

```powershell
flutter analyze
flutter test
flutter test test/preview_test.dart --dart-define=CAPTURE_UI=true
flutter build apk --debug --target-platform android-arm64
```

La prueba de capturas genera imágenes en `build/previews/`. Las pruebas cubren el flujo desde login hasta envío, permisos de asignación, cierre de mesa, separación de borradores por usuario y pérdida de respuesta con reinicio sin duplicar pedidos.

APK de prueba para celulares Android de 64 bits: `build/app/outputs/flutter-apk/app-debug.apk`. Para incluir también teléfonos de 32 bits y emuladores x86, usa `flutter build apk --debug` cuando tengas disponibles las descargas de esos componentes.

## Alcance

Esta entrega desarrolla solo la app del mozo. No implementa Laravel, cocina, caja, cobros, impresión, inventario ni creación de usuarios. La demo no sincroniza entre celulares. El historial y los estados reales dependen del backend. Las sesiones se actualizan manualmente y al volver a primer plano. La versión de publicación requerirá identidad definitiva del paquete y firma de producción; la configuración existente de release usa firma de desarrollo.
