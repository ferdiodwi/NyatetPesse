import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/history_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final transactionsAsync = ref.watch(transactionRepositoryProvider).watchAllTransactions();
    final accountsAsync = ref.watch(accountsStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── Custom Header ────────────────────────────────────────────────
          Container(
            color: AppTheme.background,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              16,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Riwayat',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                _IconBtn(icon: Icons.search_rounded, onTap: () {}),
                const SizedBox(width: 8),
                _IconBtn(icon: Icons.tune_rounded, onTap: () {}),
              ],
            ),
          ),

          // ── Filter Tabs ──────────────────────────────────────────────────
          _buildFilterTabs(ref, filter),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<TransactionEntity>>(
              stream: transactionsAsync,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                var transactions = snapshot.data ?? [];

                // Apply filter
                if (filter != TransactionFilter.all) {
                  final filterType = filter == TransactionFilter.income
                      ? 'INCOME'
                      : (filter == TransactionFilter.expense ? 'EXPENSE' : 'TRANSFER');
                  transactions = transactions.where((t) => t.type == filterType).toList();
                }

                if (transactions.isEmpty) {
                  return _EmptyState(filter: filter);
                }

                // Group by date
                final grouped = <String, List<TransactionEntity>>{};
                for (var t in transactions) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(t.transactionDate);
                  grouped.putIfAbsent(dateKey, () => []).add(t);
                }
                final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                return accountsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (accounts) {
                    final accountMap = {for (var a in accounts) a.id: a};

                    // Summary totals
                    double totalIn = 0, totalOut = 0;
                    for (var t in transactions) {
                      if (t.type == 'INCOME') totalIn += t.amount;
                      if (t.type == 'EXPENSE') totalOut += t.amount;
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(accountsStreamProvider);
                        await Future.delayed(const Duration(milliseconds: 600));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: sortedKeys.length + 1,
                        itemBuilder: (context, index) {
                          // Summary row at top
                          if (index == 0) {
                            return _SummaryRow(
                              totalIn: totalIn,
                              totalOut: totalOut,
                              currencyFormat: currencyFormat,
                            );
                          }

                          final dateKey = sortedKeys[index - 1];
                          final dayTransactions = grouped[dateKey]!;
                          final parsedDate = DateTime.parse(dateKey);
                          final now = DateTime.now();

                          String dateLabel;
                          if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day) {
                            dateLabel = 'Hari Ini';
                          } else if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day - 1) {
                            dateLabel = 'Kemarin';
                          } else {
                            dateLabel = DateFormat('d MMMM yyyy', 'id_ID').format(parsedDate);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 20, bottom: 10),
                                child: Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: dayTransactions.length,
                                  separatorBuilder: (_, i) => Divider(
                                    height: 1,
                                    indent: 68,
                                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                                  ),
                                  itemBuilder: (context, tIndex) {
                                    final t = dayTransactions[tIndex];
                                    final accountName = accountMap[t.accountId]?.name ?? '—';
                                    return _HistoryTile(
                                      transaction: t,
                                      accountName: accountName,
                                      currencyFormat: currencyFormat,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(WidgetRef ref, TransactionFilter currentFilter) {
    const filters = [
      (TransactionFilter.all, 'Semua'),
      (TransactionFilter.income, 'Masuk'),
      (TransactionFilter.expense, 'Keluar'),
      (TransactionFilter.transfer, 'Transfer'),
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: filters.map((item) {
          final isSelected = currentFilter == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(transactionFilterProvider.notifier).state = item.$1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double totalIn;
  final double totalOut;
  final NumberFormat currencyFormat;

  const _SummaryRow({required this.totalIn, required this.totalOut, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.income.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_downward_rounded, color: AppTheme.income, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Masuk', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          currencyFormat.format(totalIn),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.income),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.expense.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, color: AppTheme.expense, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Keluar', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          currencyFormat.format(totalOut),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.expense),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TransactionEntity transaction;
  final String accountName;
  final NumberFormat currencyFormat;

  const _HistoryTile({required this.transaction, required this.accountName, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == 'INCOME';
    final isExpense = t.type == 'EXPENSE';

    final Color typeColor;
    final IconData typeIcon;
    final String sign;
    if (isIncome) {
      typeColor = AppTheme.income;
      typeIcon = Icons.arrow_downward_rounded;
      sign = '+ ';
    } else if (isExpense) {
      typeColor = AppTheme.expense;
      typeIcon = Icons.arrow_upward_rounded;
      sign = '- ';
    } else {
      typeColor = AppTheme.transfer;
      typeIcon = Icons.swap_horiz_rounded;
      sign = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.merchant ?? (isIncome ? 'Pemasukan' : (isExpense ? 'Pengeluaran' : 'Transfer')),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$accountName • ${DateFormat('HH:mm').format(t.transactionDate)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '$sign${currencyFormat.format(t.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isIncome ? AppTheme.income : (isExpense ? AppTheme.expense : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TransactionFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada transaksi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba ubah filter atau tambah transaksi baru',
            style: TextStyle(fontSize: 13, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}
