import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_chifacentro/src/application/app_controller.dart';
import 'package:proyecto_chifacentro/src/data/demo_repository.dart';
import 'package:proyecto_chifacentro/src/data/local_store.dart';
import 'package:proyecto_chifacentro/src/domain/models.dart';

class LostResponseRepository extends DemoRepository {
  LostResponseRepository({required super.store}) : super(delay: Duration.zero);
  bool loseNext = true;
  @override
  Future<ServiceOrder> sendOrder(OrderDraft draft) async {
    final order = await super.sendOrder(draft);
    if (loseNext) {
      loseNext = false;
      throw const AppException('Se perdió la respuesta después de guardar.');
    }
    return order;
  }
}

void main() {
  test(
    'Reintenta tras reinicio sin duplicar un pedido cuya respuesta se perdio',
    () async {
      final store = MemoryStore();
      final repository = LostResponseRepository(store: store);
      final c = AppController(repository: repository, store: store);
      await c.login('mozo', '123456');
      final product = c.products.first;
      await c.changeLine('1', product, delta: 2, notes: 'Sin cebolla');
      final key = c.draftFor('1')!.key;
      expect(await c.sendOrder('1'), isFalse);
      expect(c.draftFor('1')!.pending, isTrue);
      expect(await c.changeLine('1', product, delta: 1), isFalse);
      expect(c.draftFor('1')!.quantity, 2);
      c.dispose();
      final restarted = AppController(
        repository: DemoRepository(store: store, delay: Duration.zero),
        store: store,
      );
      addTearDown(restarted.dispose);
      await restarted.login('mozo', '123456');
      expect(restarted.draftFor('1')!.key, key);
      expect(await restarted.sendOrder('1'), isTrue);
      expect(restarted.orders, hasLength(1));
      expect(restarted.orders.single.lines.single.notes, 'Sin cebolla');
      expect(restarted.drafts, isEmpty);
    },
  );

  test(
    'Clave de administrador, exclusividad y borradores protegen asignaciones',
    () async {
      final store = MemoryStore();
      final c = AppController(
        repository: DemoRepository(store: store, delay: Duration.zero),
        store: store,
      );
      addTearDown(c.dispose);
      await c.login('mozo', '123456');
      expect(await c.assignTables(['1', '7'], 'incorrecta'), isFalse);
      expect(c.myTables, hasLength(4));
      expect(await c.assignTables(['1', '5'], '2468'), isFalse);
      expect(await c.assignTables(['1', '7'], '2468'), isTrue);
      expect(c.myTables.map((t) => t.id), ['1', '7']);
      await c.changeLine('7', c.products.first, delta: 1);
      expect(await c.assignTables(['1'], '2468'), isFalse);
      expect(await c.changeLine('5', c.products.first, delta: 1), isFalse);
    },
  );

  test(
    'Pedidos adicionales, anulacion autorizada, entrega y nueva atencion',
    () async {
      final store = MemoryStore();
      final c = AppController(
        repository: DemoRepository(store: store, delay: Duration.zero),
        store: store,
      );
      addTearDown(c.dispose);
      await c.login('mozo', '123456');
      await c.changeLine('1', c.products.first, delta: 1);
      expect(await c.sendOrder('1'), isTrue);
      final first = c.orders.single;
      await c.changeLine('1', c.products[1], delta: 1);
      await c.sendOrder('1');
      expect(c.tables.first.totalCents, 4300);
      expect(await c.closeTable('1'), isFalse);
      final second = c.orders.first;
      expect(
        await c.cancelOrder(second.id, 'Cliente cambió de opinión', '0000'),
        isFalse,
      );
      expect(
        await c.cancelOrder(second.id, 'Cliente cambió de opinión', '2468'),
        isTrue,
      );
      expect(c.tables.first.totalCents, 1800);
      await c.deliverOrder(first.id);
      await c.changeLine('1', c.products[2], delta: 1);
      expect(await c.closeTable('1'), isFalse);
      await c.discardDraft('1');
      expect(await c.closeTable('1'), isTrue);
      expect(c.tables.first.occupied, isFalse);
      expect(c.tables.first.totalCents, 0);
      expect(c.orders.every((o) => o.closedAt != null), isTrue);
      await c.changeLine('1', c.products[2], delta: 1);
      await c.sendOrder('1');
      expect(c.tables.first.totalCents, 1600);
      expect(c.orders.where((o) => o.closedAt == null), hasLength(1));
      // A repeated close for the old orders must not close a new attention.
      await c.repository.closeTable('1', [first.id, second.id]);
      await c.refresh();
      expect(c.tables.first.occupied, isTrue);
      expect(c.tables.first.totalCents, 1600);
    },
  );

  test('Recupera recibos aunque la mesa cambie de asignacion', () async {
    final store = MemoryStore();
    final repo = LostResponseRepository(store: store);
    final c = AppController(repository: repo, store: store);
    addTearDown(c.dispose);
    await c.login('mozo', '123456');
    await c.changeLine('1', c.products.first, delta: 1);
    expect(await c.sendOrder('1'), isFalse);
    final received = (await repo.load()).orders.single;
    await repo.deliverOrder(received.id);
    await repo.closeTable('1', [received.id]);
    await repo.assignTables(['2', '3', '4'], '2468');
    await c.refresh();
    expect(c.myTables.any((t) => t.id == '1'), isFalse);
    expect(await c.assignTables(['2', '3', '4'], '2468'), isTrue);
    expect(await c.sendOrder('1'), isTrue);
    expect(c.orders, hasLength(1));
    expect(c.drafts, isEmpty);
  });

  test(
    'Borradores se separan por usuario y un envio sin red se recupera',
    () async {
      final store = MemoryStore();
      final repo = DemoRepository(store: store, delay: Duration.zero);
      final c = AppController(repository: repo, store: store);
      addTearDown(c.dispose);
      await c.login('mozo', '123456');
      await c.changeLine('1', c.products.first, delta: 1);
      repo.offline = true;
      expect(await c.sendOrder('1'), isFalse);
      final key = c.draftFor('1')!.key;
      repo.offline = false;
      await c.logout();
      await c.login('lucia', '123456');
      expect(c.drafts, isEmpty);
      await c.logout();
      await c.login('mozo', '123456');
      expect(c.draftFor('1')!.key, key);
      expect(await c.sendOrder('1'), isTrue);
      expect(c.orders, hasLength(1));
    },
  );
}
