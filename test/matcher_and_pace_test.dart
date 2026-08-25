import 'package:flutter_test/flutter_test.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/inbox/domain/services/account_matcher.dart';
import 'package:nyatet_pesse/features/reports/domain/budget_pace.dart';

Account acc(int id, String name) => Account(
      id: id,
      name: name,
      type: 'BANK',
      initialBalance: 0,
      currentBalance: 0,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('AccountMatcher.matchAccount', () {
    final accounts = [
      acc(1, 'BCA'),
      acc(2, 'DANA Utama'),
      acc(3, 'Dompet Cash'),
      acc(4, 'GoPay'),
    ];

    test('packageName BCA cocok ke akun BCA', () {
      expect(AccountMatcher.matchAccount(accounts, 'com.bca.mybca'), 1);
    });

    test('packageName DANA cocok ke akun DANA Utama', () {
      expect(AccountMatcher.matchAccount(accounts, 'id.dana'), 2);
    });

    test('Gojek cocok ke GoPay via keyword gojek', () {
      expect(AccountMatcher.matchAccount(accounts, 'com.gojek.app'), 4);
    });

    test('return null bila tidak ada yang cocok', () {
      expect(AccountMatcher.matchAccount(accounts, 'com.whatsapp'), isNull);
      expect(AccountMatcher.matchAccount(accounts, null), isNull);
    });

    test('case-insensitive terhadap nama akun', () {
      expect(AccountMatcher.matchAccount([acc(9, 'bca tabungan')], 'com.bca'), 9);
    });

    test('sumber dikenali tapi akun tidak ada → null (bukan acak)', () {
      expect(AccountMatcher.matchAccount([acc(3, 'Dompet Cash')], 'id.dana'), isNull);
    });
  });

  group('BudgetPace', () {
    BudgetPace pace(double limit, double spent, int day, {int month = 8, int year = 2026}) =>
        BudgetPace(totalLimit: limit, totalSpent: spent, now: DateTime(year, month, day));

    test('menghitung sisa aman per hari di tengah bulan', () {
      // Agustus 2026 = 31 hari. Tanggal 11 → sisa 21 hari (termasuk hari ini).
      final p = pace(3100000, 1000000, 11);
      expect(p.remaining, 2100000);
      expect(p.daysLeft, 21);
      expect(p.safePerDay, closeTo(100000, 0.01));
      expect(p.overBudget, isFalse);
      expect(p.progress, closeTo(1000000 / 3100000, 0.001));
    });

    test('hari terakhir bulan → daysLeft 1', () {
      final p = pace(1000000, 500000, 31);
      expect(p.daysLeft, 1);
      expect(p.safePerDay, 500000);
    });

    test('over budget → safePerDay nol dan overBudget true', () {
      final p = pace(1000000, 1200000, 15);
      expect(p.overBudget, isTrue);
      expect(p.safePerDay, 0);
      expect(p.progress, 1.0); // clamp
    });

    test('progress clamp di 1.0 saat spent jauh melebihi limit', () {
      final p = pace(1000000, 5000000, 10);
      expect(p.progress, 1.0);
    });

    test('budget nol → progress nol, tanpa div-by-zero', () {
      final p = pace(0, 0, 15);
      expect(p.progress, 0);
      expect(p.overBudget, isTrue); // remaining = 0
    });
  });
}
