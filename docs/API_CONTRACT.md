# Contrato propuesto para Laravel

Este contrato describe lo que consume el frontend; no implementa el backend. Las rutas y el mapeo JSON se centralizan en `lib/src/data/api_repository.dart` y `lib/src/domain/models.dart`. Si las APIs finales difieren, se adaptan allí, sin reescribir las pantallas.

## Configuración

Base HTTPS de ejemplo: `https://tu-dominio.com/api/v1`.

```powershell
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://tu-dominio.com/api/v1
```

El modo real nunca utiliza datos demo como respaldo. Android permite Internet y rechaza tráfico HTTP sin cifrar. El token se mantiene únicamente en memoria: cada apertura desde cero requiere iniciar sesión. Las contraseñas no se guardan. Los borradores se guardan en almacenamiento privado Android, separados por URL de backend y usuario.

## Convenciones

- Cabeceras: `Accept: application/json`, `Content-Type: application/json` cuando hay cuerpo y `Authorization: Bearer <token>` después de iniciar sesión.
- IDs: cadenas o enteros; la app los convierte a cadenas.
- Importes: **enteros en céntimos de soles**. `1800` representa S/ 18.00. No enviar números decimales ni cadenas para estos campos.
- Fechas: ISO 8601 con zona horaria, preferiblemente UTC (`2026-11-01T15:30:00Z`).
- Respuestas de éxito: `{ "data": ... }`. Las mutaciones sin datos pueden devolver HTTP 204.
- Las tres colecciones GET devuelven arreglos completos bajo `data`. Esta primera versión no implementa paginación; si se añade, se debe adaptar el repositorio.
- Error: HTTP 401, 403, 409, 422 o 5xx con `{ "message": "Texto comprensible para el mozo", "errors": { ... } }`. La app muestra `message`.
- HTTP 401 indica sesión vencida. El usuario puede cerrar sesión y volver a ingresar conservando sus borradores.

## Operaciones

| Método | Ruta | Cuerpo | Respuesta `data` |
|---|---|---|---|
| POST | `/auth/login` | `username`, `password`, `device_name` | `token`, `user` |
| POST | `/auth/logout` | Sin cuerpo | 204; revocar token actual |
| GET | `/tables` | — | Arreglo de mesas visibles para asignación |
| GET | `/menu` | — | Arreglo de productos, incluyendo agotados |
| GET | `/orders` | — | Pedidos del mozo autenticado, recientes primero |
| PUT | `/me/tables` | `table_ids: ["1","7"]`, `admin_password` | 204; reemplaza asignación del turno |
| POST | `/orders` | Ver ejemplo | Pedido confirmado |
| POST | `/orders/{id}/deliver` | Sin cuerpo | 204; marcar entregado |
| POST | `/orders/{id}/cancel` | `reason`, `admin_password` | 204; anular pedido completo |
| POST | `/tables/{id}/close` | `order_ids: ["1001", "1002"]` | 204; cerrar atención y liberar mesa |

### Acceso

```json
{
  "data": {
    "token": "token-emitido-por-laravel",
    "user": { "id": "1", "name": "Diego Ramírez", "username": "mozo" }
  }
}
```

La creación de usuarios y la administración de la carta pertenecen al backend. La clave de administrador debe verificarse **en el servidor**, con límites de intentos y registro de auditoría. La clave `2468` existe exclusivamente en el repositorio de demostración.

### Mesa

```json
{
  "id": "1",
  "number": 1,
  "seats": 4,
  "zone": "Salón principal",
  "waiter_id": "1",
  "occupied": true,
  "total_cents": 3600
}
```

`waiter_id: null` significa sin asignación. `occupied` indica atención activa y `total_cents` suma sus pedidos no anulados. El cierre conserva la asignación al mozo, pone la mesa disponible y conserva el historial. No registra pagos.

Si todos los pedidos se anulan, la atención sigue abierta con total cero hasta que el mozo cierre la mesa. La anulación por sí sola no debe liberar ni permitir transferir la mesa.

La asignación es por turno; Laravel determina el turno actual. Debe ser atómica: una mesa no puede pertenecer a dos mozos. Rechazar con 409 si hay un conflicto concurrente. Impedir quitar o transferir mesas con atención activa. El frontend también impide quitar mesas con borradores locales.

### Producto

```json
{
  "id": "1",
  "name": "Arroz chaufa de pollo",
  "description": "Arroz al wok, pollo, huevo y cebollita china.",
  "category": "Chaufas",
  "price_cents": 1800,
  "available": true,
  "featured": true
}
```

`featured` es opcional y vale `false` por defecto. Cantidad de mesas, platos, categorías, disponibilidad y precios provienen de estas respuestas. Las ilustraciones actuales se dibujan en la app por categoría y no requieren URLs de imágenes.

### Enviar pedido

Cabecera obligatoria: `Idempotency-Key: <identificador-del-borrador>`.

```json
{
  "table_id": "1",
  "items": [
    { "product_id": "1", "quantity": 2, "notes": "Sin cebolla" }
  ]
}
```

La app **no envía precios ni el ID del mozo**: Laravel obtiene el usuario del token, valida la asignación, consulta precios y disponibilidad y calcula el total. Cantidades entre 1 y 99; observaciones de hasta 250 caracteres. Una línea por producto: su observación se aplica a todas las unidades de esa línea.

Respuesta de creación o reintento confirmado:

```json
{
  "data": {
    "id": "1001",
    "table_id": "1",
    "table_number": 1,
    "waiter_id": "1",
    "created_at": "2026-11-01T15:30:00Z",
    "closed_at": null,
    "status": "sent",
    "cancellation_reason": null,
    "lines": [
      { "product_id": "1", "name": "Arroz chaufa de pollo", "price_cents": 1800, "quantity": 2, "notes": "Sin cebolla" }
    ]
  }
}
```

Cada pedido adicional es un pedido nuevo asociado a la atención activa de la mesa. Las líneas enviadas no se editan: un pedido `sent` puede anularse completo con motivo y autorización; luego se envía el correcto.

## Reintentos y prevención de duplicados

1. Antes de enviar, la app persiste el contenido y su clave. Deshabilita edición y descarte mientras el resultado sea incierto.
2. Ante una respuesta perdida, desconexión, 409 o 5xx, conserva la misma clave y el mismo cuerpo, incluso tras reiniciar o cerrar sesión.
3. Laravel debe guardar y resolver la clave **en la misma transacción que el pedido**, con restricción única por usuario y clave. Una repetición debe devolver el mismo pedido, aunque ya se entregó o cerró su mesa. Consultar primero el recibo de idempotencia antes de validar el estado actual de esa mesa.
4. Si la misma clave llega con otro cuerpo, responder 409 sin crear otro pedido. No caducar el recibo mientras pueda existir un reintento del cliente; conservarlo junto al pedido archivado.
5. HTTP 400, 401, 403, 404 y 422 se consideran rechazo definitivo **sin pedido creado**: la app desbloquea el borrador y genera una nueva clave para corregirlo. Nunca devolver esos estados después de confirmar el pedido. Excepción: si un envío ya estaba pendiente y el reintento recibe 401, la app conserva su clave y contenido hasta volver a iniciar sesión; esa respuesta de autenticación no permite saber si el primer envío se guardó.
6. El backend debe aplicar también operaciones idempotentes a entrega, anulación y cierre. El cierre incluye `order_ids`: todos los pedidos de la atención que el mozo está viendo, incluidos los anulados. En una transacción, comprobar que coinciden exactamente con la atención activa y cerrar solo ese conjunto. Si ya están cerrados, devolver éxito sin afectar una atención posterior; si se agregó otro pedido o cambió la atención, responder 409 y exigir actualizar. No cerrar la mesa actual ignorando esos IDs.

## Estados y autorización

Estados admitidos: `sent`, `preparing`, `ready`, `delivered`, `cancelled`.

El mozo marca un pedido como entregado cuando los platos llegaron a la mesa. Los estados de preparación podrían actualizarse desde el backend; la app los consulta al refrescar o al volver a primer plano. Cocina y caja quedan fuera del alcance implementado.

Laravel debe autorizar cada operación mediante el token, sin confiar en controles del frontend. Anulación: solo estado `sent`, motivo obligatorio y clave correcta. Cierre: todos los pedidos no anulados de la atención deben estar entregados. Rechazar con 409 cambios incompatibles de estado o asignación.

## Pendiente de la integración real

Confirmar rutas y nombres finales, implementar este contrato, probar con dos celulares simultáneos, validar estados y expiración de tokens, y comprobar los reintentos contra Laravel. La demostración y las pruebas de transporte no sustituyen estas pruebas de integración.
