import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';

final recurringTransactionsProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.recurringTransactions)
        ..orderBy([(t) => OrderingTerm.asc(t.nextDate)]))
      .watch();
});

class RecurringController extends StateNotifier<bool> {
  final AppDatabase _db;

  RecurringController(this._db) : super(false);

  Future<void> addRecurring({
    required String type,
    required double amount,
    required int accountId,
    int? categoryId,
    String? merchant,
    String? note,
    required String interval, // 'daily', 'weekly', 'monthly'
    required DateTime nextDate,
  }) async {
    state = true;
    try {
      await _db.into(_db.recurringTransactions).insert(
        RecurringTransactionsCompanion.insert(
          type: type,
          amount: amount,
          accountId: accountId,
          categoryId: Value(categoryId),
          merchant: Value(merchant),
          note: Value(note),
          interval: interval,
          nextDate: nextDate,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      state = false;
    }
  }

  Future<void> deleteRecurring(int id) async {
    await (_db.delete(_db.recurringTransactions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleActive(int id, bool isActive) async {
    await (_db.update(_db.recurringTransactions)..where((t) => t.id.equals(id)))
        .write(RecurringTransactionsCompanion(isActive: Value(isActive)));
  }

  Future<void> processDueTransactions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final dueItems = await (_db.select(_db.recurringTransactions)
          ..where((t) => t.isActive.equals(true) & t.nextDate.isSmallerOrEqualValue(today)))
        .get();

    for (final item in dueItems) {
      // 1. Insert transaction
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          type: item.type,
          amount: item.amount,
          accountId: item.accountId,
          categoryId: Value(item.categoryId),
          merchant: Value(item.merchant),
          description: Value(item.note),
          transactionDate: item.nextDate,
          source: 'recurring',
          status: const Value('confirmed'),
          isRecurring: const Value(true),
          recurringId: Value(item.id),
          createdAt: DateTime.now(),
        ),
      );

      // 2. Update account balance
      final isExpense = item.type == 'EXPENSE';
      final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(item.accountId))).getSingle();
      
      final newBalance = isExpense ? account.currentBalance - item.amount : account.currentBalance + item.amount;
      
      await (_db.update(_db.accounts)..where((a) => a.id.equals(item.accountId))).write(
        AccountsCompanion(
          currentBalance: Value(newBalance),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 3. Update next date for recurring item
      DateTime next = item.nextDate;
      if (item.interval == 'daily') {
        next = next.add(const Duration(days: 1));
      } else if (item.interval == 'weekly') {
        next = next.add(const Duration(days: 7));
      } else if (item.interval == 'monthly') {
        next = DateTime(next.year, next.month + 1, next.day);
      }
      
      // If it's still in the past (e.g. app hasn't been opened in a long time), jump to next future date?
      // For now, just jump once to prevent mass inserts unless we loop it.
      // To loop catching up:
      while (next.isBefore(today)) {
         if (item.interval == 'daily') next = next.add(const Duration(days: 1));
         else if (item.interval == 'weekly') next = next.add(const Duration(days: 7));
         else if (item.interval == 'monthly') next = DateTime(next.year, next.month + 1, next.day);
      }

      await (_db.update(_db.recurringTransactions)..where((t) => t.id.equals(item.id)))
          .write(RecurringTransactionsCompanion(nextDate: Value(next)));
    }
  }
}

final recurringControllerProvider = StateNotifierProvider<RecurringController, bool>((ref) {
  final db = ref.watch(databaseProvider);
  return RecurringController(db);
});
