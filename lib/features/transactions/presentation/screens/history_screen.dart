import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/core/widgets/error_retry_widget.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/history_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final period = ref.watch(historyPeriodProvider);
    final accountFilter = ref.watch(historyAccountFilterProvider);
    final transactionsAsync = ref.watch(transactionRepositoryProvider).watchAllTransactions();
    final accountsAsync = ref.watch(accountsStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final hasAdvancedFilter = period != HistoryPeriod.all || accountFilter != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Custom Header ────────────────────────────────────────────────
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                _IconBtn(
                  icon: Icons.search_rounded,
                  onTap: () => showSearch(
                    context: context,
                    delegate: TransactionSearchDelegate(
                      stream: transactionsAsync,
                      accountsAsync: accountsAsync,
                      currencyFormat: currencyFormat,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _IconBtn(
                  icon: Icons.tune_rounded,
                  badge: hasAdvancedFilter,
                  onTap: () => _showAdvancedFilterSheet(context, ref, accountsAsync),
                ),
              ],
            ),
          ),

          // ── Filter Tabs ──────────────────────────────────────────────────
          _buildFilterTabs(context, ref, filter),

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

                // ── Filter tipe (case-insensitive) ──────────────────────
                if (filter != TransactionFilter.all) {
                  final filterType = filter == TransactionFilter.income
                      ? 'income'
                      : (filter == TransactionFilter.expense ? 'expense' : 'transfer');
                  transactions =
                      transactions.where((t) => t.type.toLowerCase() == filterType).toList();
                }

                // ── Filter periode ──────────────────────────────────────
                final now = DateTime.now();
                DateTime? cutoff;
                switch (period) {
                  case HistoryPeriod.last7Days:
                    cutoff = DateTime(now.year, now.month, now.day - 6);
                    break;
                  case HistoryPeriod.last30Days:
                    cutoff = DateTime(now.year, now.month, now.day - 29);
                    break;
                  case HistoryPeriod.thisMonth:
                    cutoff = DateTime(now.year, now.month, 1);
                    break;
                  case HistoryPeriod.all:
                    break;
                }
                if (cutoff != null) {
                  transactions =
                      transactions.where((t) => !t.transactionDate.isBefore(cutoff!)).toList();
                }

                // ── Filter akun ─────────────────────────────────────────
                if (accountFilter != null) {
                  transactions =
                      transactions.where((t) => t.accountId == accountFilter).toList();
                }

                if (transactions.isEmpty) {
                  return _EmptyState(filter: filter, hasAdvancedFilter: hasAdvancedFilter);
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
                  error: (e, st) => ErrorRetryWidget(
                    message: 'Gagal memuat akun',
                    onRetry: () => ref.invalidate(accountsStreamProvider),
                  ),
                  data: (accounts) {
                    final accountMap = {for (var a in accounts) a.id: a};

                    // Summary totals (case-insensitive)
                    double totalIn = 0, totalOut = 0;
                    for (var t in transactions) {
                      final type = t.type.toLowerCase();
                      if (type == 'income') totalIn += t.amount;
                      if (type == 'expense') totalOut += t.amount;
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(accountsStreamProvider);
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
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
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                  ),
                                  itemBuilder: (context, tIndex) {
                                    final t = dayTransactions[tIndex];
                                    final accountName = accountMap[t.accountId]?.name ?? '—';
                                    return Dismissible(
                                      key: ValueKey(t.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: AppTheme.expense.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(Icons.delete_outline_rounded,
                                            color: AppTheme.expense),
                                      ),
                                      confirmDismiss: (_) async {
                                        return await showDialog<bool>(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20)),
                                            title: const Text('Hapus transaksi?',
                                                style: TextStyle(fontSize: 17)),
                                            content: Text(
                                              'Saldo akun akan disesuaikan otomatis.',
                                              style: const TextStyle(fontSize: 13.5),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(dialogContext, false),
                                                child: const Text('Batal'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(dialogContext, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.expense,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(12)),
                                                ),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onDismissed: (_) async {
                                        await ref
                                            .read(transactionRepositoryProvider)
                                            .deleteTransaction(t);
                                      },
                                      child: _HistoryTile(
                                        transaction: t,
                                        accountName: accountName,
                                        currencyFormat: currencyFormat,
                                      ),
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

  void _showAdvancedFilterSheet(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Account>> accountsAsync,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).hintColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter Lanjutan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PERIODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Consumer(builder: (context, ref, _) {
                final current = ref.watch(historyPeriodProvider);
                return Wrap(
                  spacing: 8,
                  children: [
                    (HistoryPeriod.all, 'Semua'),
                    (HistoryPeriod.last7Days, '7 Hari'),
                    (HistoryPeriod.last30Days, '30 Hari'),
                    (HistoryPeriod.thisMonth, 'Bulan Ini'),
                  ].map((item) {
                    final selected = current == item.$1;
                    return ChoiceChip(
                      label: Text(item.$2),
                      selected: selected,
                      onSelected: (_) =>
                          ref.read(historyPeriodProvider.notifier).state = item.$1,
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 16),
              Text(
                'AKUN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              accountsAsync.when(
                loading: () => const CircularProgressIndicator(strokeWidth: 2),
                error: (e, _) => Text('Gagal memuat akun',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.error)),
                data: (accounts) => Consumer(builder: (context, ref, _) {
                  final current = ref.watch(historyAccountFilterProvider);
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua Akun'),
                        selected: current == null,
                        onSelected: (_) =>
                            ref.read(historyAccountFilterProvider.notifier).state = null,
                      ),
                      ...accounts.map((a) => ChoiceChip(
                            label: Text(a.name),
                            selected: current == a.id,
                            onSelected: (_) =>
                                ref.read(historyAccountFilterProvider.notifier).state = a.id,
                          )),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Selesai',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, WidgetRef ref, TransactionFilter currentFilter) {
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
        color: Theme.of(context).colorScheme.surface,
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
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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

// ── Search ─────────────────────────────────────────────────────────────────────
class TransactionSearchDelegate extends SearchDelegate<TransactionEntity?> {
  final Stream<List<TransactionEntity>> stream;
  final AsyncValue<List<Account>> accountsAsync;
  final NumberFormat currencyFormat;

  TransactionSearchDelegate({
    required this.stream,
    required this.accountsAsync,
    required this.currencyFormat,
  });

  @override
  String get searchFieldLabel => 'Cari merchant, catatan, atau nominal...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => close(context, null),
    );
  }

  List<TransactionEntity> _filter(List<TransactionEntity> transactions, String q) {
    return searchTransactions(transactions, q);
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    // Subscribe sendiri ke stream supaya hasil pencarian selalu data terbaru.
    return StreamBuilder<List<TransactionEntity>>(
      stream: stream,
      builder: (context, snapshot) {
        final results = _filter(snapshot.data ?? const [], query);

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).hintColor),
                const SizedBox(height: 12),
                Text(
                  query.isEmpty
                      ? 'Mulai ketik untuk mencari transaksi'
                      : 'Tidak ada hasil untuk "$query"',
                  style: TextStyle(
                      fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        final accountMap = {
          for (final a in (accountsAsync.valueOrNull ?? const <Account>[])) a.id: a,
        };

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: results.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 68,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, i) {
            final t = results[i];
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _HistoryTile(
                transaction: t,
                accountName: accountMap[t.accountId]?.name ?? '—',
                currencyFormat: currencyFormat,
              ),
            );
          },
        );
      },
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
                        Text('Total Masuk', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                        Text('Total Keluar', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
    // Case-insensitive: transaksi dari parser lowercase, dari UI uppercase.
    final type = t.type.toLowerCase();
    final isIncome = type == 'income';
    final isExpense = type == 'expense';

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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$accountName • ${DateFormat('HH:mm').format(t.transactionDate)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '$sign${currencyFormat.format(t.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isIncome ? AppTheme.income : (isExpense ? AppTheme.expense : Theme.of(context).colorScheme.onSurface),
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
  final bool badge;
  const _IconBtn({required this.icon, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface)),
            if (badge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.transfer,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TransactionFilter filter;
  final bool hasAdvancedFilter;
  const _EmptyState({required this.filter, required this.hasAdvancedFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Text(
            'Tidak ada transaksi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            hasAdvancedFilter
                ? 'Coba longgarkan filter periode/akun'
                : 'Coba ubah filter atau tambah transaksi baru',
            style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
