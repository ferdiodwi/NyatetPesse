import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            name: 'BCA',
            type: 'BANK',
            currentBalance: const Value(1000000),
            createdAt: DateTime.now(),
          ),
        );
  });

  tearDown(() => db.close());

  Future<int> seedTransaction({
    required double amount,
    required DateTime date,
    String type = 'expense',
    int accountId = 1,
  }) {
    return db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            type: type,
            amount: amount,
            accountId: accountId,
            transactionDate: date,
            source: 'notification',
            createdAt: DateTime.now(),
          ),
        );
  }

  group('findPotentialDuplicates', () {
    test('detects same account + amount within ±1 day', () async {
      final now = DateTime.now();
      await seedTransaction(amount: 50000, date: now.subtract(const Duration(hours: 3)));

      final found = await repo.findPotentialDuplicates(
        accountId: 1,
        amount: 50000,
        nearDate: now,
      );
      expect(found, hasLength(1));
    });

    test('detects near-identical amounts (toleransi pembulatan)', () async {
      final now = DateTime.now();
      await seedTransaction(amount: 50000.00, date: now);

      final found = await repo.findPotentialDuplicates(
        accountId: 1,
        amount: 50000.005,
        nearDate: now,
      );
      expect(found, hasLength(1));
    });

    test('ignores different amount', () async {
      final now = DateTime.now();
      await seedTransaction(amount: 50000, date: now);

      final found = await repo.findPotentialDuplicates(
        accountId: 1,
        amount: 99000,
        nearDate: now,
      );
      expect(found, isEmpty);
    });

    test('ignores transaction older than 1 day', () async {
      final now = DateTime.now();
      await seedTransaction(
        amount: 50000,
        date: now.subtract(const Duration(days: 3)),
      );

      final found = await repo.findPotentialDuplicates(
        accountId: 1,
        amount: 50000,
        nearDate: now,
      );
      expect(found, isEmpty);
    });

    test('ignores same amount on different account', () async {
      final now = DateTime.now();
      await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'Cash',
              type: 'CASH',
              createdAt: DateTime.now(),
            ),
          );
      await seedTransaction(amount: 50000, date: now, accountId: 2);

      final found = await repo.findPotentialDuplicates(
        accountId: 1,
        amount: 50000,
        nearDate: now,
      );
      expect(found, isEmpty);
    });
  });

  group('addTransaction normalisasi tipe', () {
    // Catatan: onCreate seed otomatis membuat akun 'Cash' (id=1),
    // sehingga 'BCA' yang di-seed setUp berada di id berikutnya.
    Future<int> bcaAccountId() async {
      final acc = await (db.select(db.accounts)
            ..where((a) => a.name.equals('BCA')))
          .getSingle();
      return acc.id;
    }

    test('lowercase expense tetap mengurangi saldo', () async {
      final accountId = await bcaAccountId();
      await repo.addTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amount: 25000,
        accountId: accountId,
        transactionDate: DateTime.now(),
        source: 'notification',
        createdAt: DateTime.now(),
      ));

      final account = await (db.select(db.accounts)
            ..where((a) => a.id.equals(accountId)))
          .getSingle();
      expect(account.currentBalance, 975000);
    });

    test('UPPERCASE EXPENSE juga mengurangi saldo (tidak dobel)', () async {
      final accountId = await bcaAccountId();
      await repo.addTransaction(TransactionsCompanion.insert(
        type: 'EXPENSE',
        amount: 25000,
        accountId: accountId,
        transactionDate: DateTime.now(),
        source: 'manual',
        createdAt: DateTime.now(),
      ));

      final account = await (db.select(db.accounts)
            ..where((a) => a.id.equals(accountId)))
          .getSingle();
      // Tepat satu kali pengurangan — bukan nol atau dua kali.
      expect(account.currentBalance, 975000);
    });
  });
}
