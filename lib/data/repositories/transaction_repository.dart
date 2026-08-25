import 'package:drift/drift.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';

class TransactionRepository {
  final AppDatabase _db;

  TransactionRepository(this._db);

  Stream<List<TransactionEntity>> watchAllTransactions() {
    return (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
        .watch();
  }
  
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 5}) {
    return (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  /// Deteksi duplikat: transaksi dengan akun sama, nominal sama (toleransi
  /// pembulatan), dalam rentang ±1 hari dari tanggal referensi.
  Future<List<TransactionEntity>> findPotentialDuplicates({
    required int accountId,
    required double amount,
    DateTime? nearDate,
  }) {
    final ref = nearDate ?? DateTime.now();
    final from = ref.subtract(const Duration(days: 1));
    final to = ref.add(const Duration(days: 1));

    return (_db.select(_db.transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..where((t) => t.amount.isBiggerOrEqualValue(amount - 0.01))
          ..where((t) => t.amount.isSmallerOrEqualValue(amount + 0.01))
          ..where((t) => t.transactionDate.isBetweenValues(from, to)))
        .get();
  }

  Future<int> addTransaction(TransactionsCompanion transaction) async {
    return await _db.transaction(() async {
      // 1. Insert transaction
      final id = await _db.into(_db.transactions).insert(transaction);

      // 2. Update account balance — normalisasi casing agar konsisten
      //    di semua sumber (parser kirim lowercase, UI kirim uppercase).
      final amount = transaction.amount.value;
      final type = transaction.type.value.toLowerCase();
      final accountId = transaction.accountId.value;

      final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingle();

      double newBalance = account.currentBalance;
      if (type == 'income') {
        newBalance += amount;
      } else if (type == 'expense') {
        newBalance -= amount;
      } else if (type == 'transfer') {
        newBalance -= amount; // Source account decreases

        // Target account increases
        final destAccountId = transaction.destinationAccountId.value;
        if (destAccountId != null) {
           final destAccount = await (_db.select(_db.accounts)..where((a) => a.id.equals(destAccountId))).getSingle();
           await _db.update(_db.accounts).replace(destAccount.copyWith(currentBalance: destAccount.currentBalance + amount));
        }
      }

      await _db.update(_db.accounts).replace(account.copyWith(currentBalance: newBalance));

      return id;
    });
  }

  Future<bool> deleteTransaction(TransactionEntity transaction) async {
    return await _db.transaction(() async {
       // Reverse balance logic before deleting
       final amount = transaction.amount;
       final type = transaction.type;
       final accountId = transaction.accountId;
       
       final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingle();
       
       double newBalance = account.currentBalance;
       if (type == 'INCOME') {
         newBalance -= amount;
       } else if (type == 'EXPENSE') {
         newBalance += amount;
       } else if (type == 'TRANSFER') {
         newBalance += amount; // Reverse source
         
         final destAccountId = transaction.destinationAccountId;
         if (destAccountId != null) {
            final destAccount = await (_db.select(_db.accounts)..where((a) => a.id.equals(destAccountId))).getSingle();
            await _db.update(_db.accounts).replace(destAccount.copyWith(currentBalance: destAccount.currentBalance - amount));
         }
       }
       
       await _db.update(_db.accounts).replace(account.copyWith(currentBalance: newBalance));
       
       // Delete transaction
       final rowsDeleted = await _db.delete(_db.transactions).delete(transaction);
       return rowsDeleted > 0;
    });
  }
}
