import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/history_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart'; // for accountsStreamProvider

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final transactionsAsync = ref.watch(transactionRepositoryProvider).watchAllTransactions();
    final accountsAsync = ref.watch(accountsStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(context, ref, 'Semua', TransactionFilter.all, filter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Pemasukan', TransactionFilter.income, filter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Pengeluaran', TransactionFilter.expense, filter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Transfer', TransactionFilter.transfer, filter),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<TransactionEntity>>(
              stream: transactionsAsync,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                
                var transactions = snapshot.data ?? [];
                
                // Apply filter
                if (filter != TransactionFilter.all) {
                  final filterTypeStr = filter == TransactionFilter.income ? 'INCOME' : (filter == TransactionFilter.expense ? 'EXPENSE' : 'TRANSFER');
                  transactions = transactions.where((t) => t.type == filterTypeStr).toList();
                }
                
                if (transactions.isEmpty) {
                  return const Center(child: Text('Tidak ada transaksi sesuai filter'));
                }
                
                // Group by date
                final grouped = <String, List<TransactionEntity>>{};
                for (var t in transactions) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(t.transactionDate);
                  if (!grouped.containsKey(dateKey)) {
                    grouped[dateKey] = [];
                  }
                  grouped[dateKey]!.add(t);
                }
                
                final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
                
                return accountsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (accounts) {
                    final accountMap = {for (var a in accounts) a.id: a};
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedKeys[index];
                        final dayTransactions = grouped[dateKey]!;
                        
                        // Parse date string to DateTime to format it nicely
                        final parsedDate = DateTime.parse(dateKey);
                        final now = DateTime.now();
                        String dateLabel;
                        if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day) {
                          dateLabel = 'Hari Ini';
                        } else if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day - 1) {
                          dateLabel = 'Kemarin';
                        } else {
                          dateLabel = DateFormat('d MMM yyyy').format(parsedDate);
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              child: Text(
                                dateLabel.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dayTransactions.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, tIndex) {
                                  final t = dayTransactions[tIndex];
                                  final account = accountMap[t.accountId];
                                  final accountName = account?.name ?? 'Unknown';
                                  
                                  final isIncome = t.type == 'INCOME';
                                  final isExpense = t.type == 'EXPENSE';
                                  final sign = isExpense ? '- ' : (isIncome ? '+ ' : '');
                                  
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    title: Text(
                                      t.merchant ?? (isIncome ? 'Pemasukan' : (isExpense ? 'Pengeluaran' : 'Transfer')),
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(
                                      '${t.type} • $accountName • ${DateFormat('HH:mm').format(t.transactionDate)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Text(
                                      '$sign${currencyFormat.format(t.amount)}',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isIncome ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    onTap: () {
                                       // Open details or edit
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, TransactionFilter type, TransactionFilter currentFilter) {
    final isSelected = currentFilter == type;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainer,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        ref.read(transactionFilterProvider.notifier).state = type;
      },
    );
  }
}
