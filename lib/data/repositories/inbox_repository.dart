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

  /// Dedupe capture: true bila ada item pending serupa (app + teks sama)
  /// dalam jendela waktu [within] — notifikasi ganda sering terjadi karena
  /// Android mengirim ulang notifikasi yang sama.
  Future<bool> hasRecentSimilar({
    required String sourceApp,
    required String rawText,
    Duration within = const Duration(minutes: 2),
  }) {
    final since = DateTime.now().subtract(within);
    return (_db.select(_db.inboxItems)
          ..where((t) => t.sourceApp.equals(sourceApp))
          ..where((t) => t.rawText.equals(rawText))
          ..where((t) => t.status.equals('pending'))
          ..where((t) => t.detectedAt.isBiggerThanValue(since)))
        .get()
        .then((rows) => rows.isNotEmpty);
  }

  Future<InboxItem?> getById(int id) {
    return (_db.select(_db.inboxItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
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
