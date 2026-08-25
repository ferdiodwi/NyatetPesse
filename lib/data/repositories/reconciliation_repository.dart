import 'package:drift/drift.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';

class ReconciliationRepository {
  final AppDatabase _db;

  ReconciliationRepository(this._db);

  /// Simpan hasil rekonsiliasi + sesuaikan saldo akun ke nilai aktual.
  /// Berjalan dalam satu transaksi agar saldo dan catatan konsisten.
  Future<void> reconcile({
    required Account account,
    required double actualBalance,
    String? note,
  }) async {
    final difference = actualBalance - account.currentBalance;

    await _db.transaction(() async {
      await _db.into(_db.reconciliations).insert(
            ReconciliationsCompanion.insert(
              accountId: account.id,
              recordedBalance: account.currentBalance,
              actualBalance: actualBalance,
              difference: difference,
              note: Value(note),
              reconciledAt: DateTime.now(),
            ),
          );

      await (_db.update(_db.accounts)..where((a) => a.id.equals(account.id)))
          .write(
        AccountsCompanion(
          currentBalance: Value(actualBalance),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Riwayat rekonsiliasi terbaru (lintas akun).
  Stream<List<Reconciliation>> watchRecent({int limit = 10}) {
    return (_db.select(_db.reconciliations)
          ..orderBy([(r) => OrderingTerm(expression: r.reconciledAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }
}
