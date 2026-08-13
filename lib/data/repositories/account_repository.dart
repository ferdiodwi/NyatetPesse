import 'package:nyatet_pesse/data/database/app_database.dart';

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Stream<List<Account>> watchAllAccounts() {
    return _db.select(_db.accounts).watch();
  }

  Future<int> addAccount(AccountsCompanion account) {
    return _db.into(_db.accounts).insert(account);
  }

  Future<Account> getAccountById(int id) {
    return (_db.select(_db.accounts)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<bool> updateAccount(Account account) {
    return _db.update(_db.accounts).replace(account);
  }

  Future<int> deleteAccount(Account account) {
    return _db.delete(_db.accounts).delete(account);
  }
}
