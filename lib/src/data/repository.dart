import '../domain/models.dart';

abstract interface class RestaurantRepository {
  bool get esDemo;
  Future<Waiter> iniciarSesion(String nombreUsuario, String contrasena);
  Future<void> cerrarSesion();
  Future<RestaurantSnapshot> cargar();
  Future<void> asignarMesas(List<String> idsMesas, String claveAdministrador);
  Future<ServiceOrder> enviarPedido(OrderDraft borrador);
  Future<void> anularPedido(
    String idPedido,
    String motivo,
    String claveAdministrador,
  );
  Future<void> entregarPedido(String idPedido);
  Future<void> cerrarMesa(String idMesa, List<String> idsPedidosEsperados);
  void dispose();
}
