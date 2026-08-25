import 'package:flutter_test/flutter_test.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/history_providers.dart';

TransactionEntity tx({
  required int id,
  String type = 'expense',
  double amount = 50000,
  String? merchant,
  String? description,
  DateTime? date,
}) {
  return TransactionEntity(
    id: id,
    type: type,
    amount: amount,
    accountId: 1,
    destinationAccountId: null,
    categoryId: null,
    merchant: merchant,
    description: description,
    transactionDate: date ?? DateTime(2026, 8, 20, 12, 0),
    transactionTime: null,
    source: 'manual',
    sourceApp: null,
    status: 'confirmed',
    confidenceScore: null,
    referenceId: null,
    isConfirmed: true,
    isRecurring: false,
    recurringId: null,
    createdAt: DateTime(2026, 8, 20),
    updatedAt: null,
  );
}

void main() {
  group('searchTransactions', () {
    final transactions = [
      tx(id: 1, merchant: 'Indomaret', amount: 25000, date: DateTime(2026, 8, 20)),
      tx(id: 2, merchant: 'Kopi Kenangan', amount: 18000, date: DateTime(2026, 8, 21)),
      tx(
        id: 3,
        type: 'income',
        merchant: null,
        description: 'Gaji bulanan dari kantor',
        amount: 5000000,
        date: DateTime(2026, 8, 19),
      ),
      tx(id: 4, merchant: 'Tokopedia', amount: 150000, date: DateTime(2026, 8, 18)),
    ];

    test('query kosong → semua transaksi, urut terbaru dulu', () {
      final result = searchTransactions(transactions, '');
      expect(result.map((t) => t.id).toList(), [2, 1, 3, 4]);
    });

    test('cocokkan merchant case-insensitive', () {
      final result = searchTransactions(transactions, 'indomaret');
      expect(result, hasLength(1));
      expect(result.first.id, 1);
    });

    test('cocokkan deskripsi', () {
      final result = searchTransactions(transactions, 'gaji');
      expect(result, hasLength(1));
      expect(result.first.id, 3);
    });

    test('cocokkan nominal mentah', () {
      final result = searchTransactions(transactions, '150000');
      expect(result, hasLength(1));
      expect(result.first.id, 4);
    });

    test('cocokkan nominal berformat ribuan', () {
      final result = searchTransactions(transactions, '25.000');
      expect(result, hasLength(1));
      expect(result.first.id, 1);
    });

    test('query tanpa hasil → list kosong', () {
      final result = searchTransactions(transactions, 'zomby');
      expect(result, isEmpty);
    });
  });
}
