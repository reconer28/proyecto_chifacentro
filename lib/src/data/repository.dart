import '../domain/models.dart';

abstract interface class RestaurantRepository {
  bool get isDemo;
  Future<Waiter> login(String username, String password);
  Future<void> logout();
  Future<RestaurantSnapshot> load();
  Future<void> assignTables(List<String> tableIds, String adminPassword);
  Future<ServiceOrder> sendOrder(OrderDraft draft);
  Future<void> cancelOrder(String orderId, String reason, String adminPassword);
  Future<void> deliverOrder(String orderId);
  Future<void> closeTable(String tableId, List<String> expectedOrderIds);
  void dispose();
}
