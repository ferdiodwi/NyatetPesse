import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionRepositoryProvider).watchRecentTransactions(limit: 5);
    final accountsAsync = ref.watch(accountsStreamProvider);
    // Note: categories could also be fetched here for accurate names/icons.
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Transaksi Terakhir',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Lihat Semua',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<TransactionEntity>>(
          stream: transactionsAsync,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            
            final transactions = snapshot.data ?? [];
            if (transactions.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada transaksi')));
            }
            
            return accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const SizedBox.shrink(),
              data: (accounts) {
                final accountMap = {for (var a in accounts) a.id: a};
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    final account = accountMap[t.accountId];
                    final accountName = account?.name ?? 'Unknown';
                    
                    final isIncome = t.type == 'INCOME';
                    final isExpense = t.type == 'EXPENSE';
                    
                    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                    final sign = isExpense ? '- ' : (isIncome ? '+ ' : '');
                    
                    return Column(
                      children: [
                        _buildTransactionItem(
                          context: context,
                          icon: isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          title: t.merchant ?? (isIncome ? 'Pemasukan' : (isExpense ? 'Pengeluaran' : 'Transfer')),
                          category: t.type, // Temporary: should map from category table
                          account: '$accountName • ${DateFormat('d MMM').format(t.transactionDate)}',
                          amount: '$sign${currencyFormat.format(t.amount)}',
                          isExpense: isExpense,
                          isIncome: isIncome,
                        ),
                        if (index < transactions.length - 1) const Divider(height: 1),
                      ],
                    );
                  },
                );
              }
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String category,
    required String account,
    required String amount,
    required bool isExpense,
    bool isIncome = false,
  }) {
    final bgColor = isIncome 
        ? Theme.of(context).colorScheme.secondaryContainer 
        : Theme.of(context).colorScheme.surfaceContainer; // The HTML uses surface-container for expense, secondary-container for income
    
    final iconColor = isIncome
        ? Theme.of(context).colorScheme.onSecondaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    final amountColor = isIncome
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      account,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
