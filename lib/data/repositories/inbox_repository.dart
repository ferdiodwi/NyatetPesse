import 'package:drift/drift.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';

class InboxRepository {
  final AppDatabase _db;

  InboxRepository(this._db);

  Stream<List<InboxItem>> watchPendingInboxItems() {
    return (_db.select(_db.inboxItems)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm(expression: t.detectedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<int> addInboxItem(InboxItemsCompanion item) {
    return _db.into(_db.inboxItems).insert(item);
  }

  Future<void> updateInboxItemStatus(int id, String status) {
    return (_db.update(_db.inboxItems)..where((t) => t.id.equals(id))).write(
      InboxItemsCompanion(
        status: Value(status),
        processedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteInboxItem(int id) {
    return (_db.delete(_db.inboxItems)..where((t) => t.id.equals(id))).go();
  }
}
