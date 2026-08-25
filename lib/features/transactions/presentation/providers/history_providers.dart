import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';

enum TransactionFilter { all, income, expense, transfer }

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter.all);

/// Filter rentang waktu untuk riwayat.
enum HistoryPeriod { all, last7Days, last30Days, thisMonth }

final historyPeriodProvider = StateProvider<HistoryPeriod>((ref) => HistoryPeriod.all);

/// Filter akun (null = semua akun).
final historyAccountFilterProvider = StateProvider<int?>((ref) => null);

/// Pencarian transaksi: cocokkan merchant, deskripsi, nominal mentah,
/// atau nominal berformat ribuan. Case-insensitive. Hasil diurutkan
/// dari yang terbaru.
List<TransactionEntity> searchTransactions(
  List<TransactionEntity> transactions,
  String query,
) {
  final sorted = [...transactions]
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  if (query.isEmpty) return sorted;

  final lower = query.toLowerCase();
  return sorted.where((t) {
    final merchant = (t.merchant ?? '').toLowerCase();
    final desc = (t.description ?? '').toLowerCase();
    final amount = t.amount.toInt().toString();
    final amountFormatted =
        NumberFormat.decimalPattern('id_ID').format(t.amount.toInt());
    return merchant.contains(lower) ||
        desc.contains(lower) ||
        amount.contains(lower) ||
        amountFormatted.contains(lower);
  }).toList();
}
