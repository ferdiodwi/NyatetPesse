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

  Future<int> addTransaction(TransactionsCompanion transaction) async {
    return await _db.transaction(() async {
      // 1. Insert transaction
      final id = await _db.into(_db.transactions).insert(transaction);
      
      // 2. Update account balance
      final amount = transaction.amount.value;
      final type = transaction.type.value;
      final accountId = transaction.accountId.value;
      
      final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingle();
      
      double newBalance = account.currentBalance;
      if (type == 'INCOME') {
        newBalance += amount;
      } else if (type == 'EXPENSE') {
        newBalance -= amount;
      } else if (type == 'TRANSFER') {
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
