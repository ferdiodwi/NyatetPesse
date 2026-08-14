import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionRepositoryProvider).watchRecentTransactions(limit: 5);
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppTheme.primary,
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TransactionEntity>>(
          stream: transactionsAsync,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingSkeleton();
            }
            if (snapshot.hasError) {
              return const SizedBox.shrink();
            }

            final transactions = snapshot.data ?? [];
            if (transactions.isEmpty) {
              return _EmptyState();
            }

            return accountsAsync.when(
              loading: () => const _LoadingSkeleton(),
              error: (e, st) => const SizedBox.shrink(),
              data: (accounts) {
                final accountMap = {for (var a in accounts) a.id: a};
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 68,
                      color: AppTheme.borderColor.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final account = accountMap[t.accountId];
                      return _TransactionTile(transaction: t, accountName: account?.name ?? '—');
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final String accountName;

  const _TransactionTile({required this.transaction, required this.accountName});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == 'INCOME';
    final isExpense = t.type == 'EXPENSE';
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final timeFormat = DateFormat('HH:mm');

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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(typeIcon, color: typeColor, size: 19),
          ),

          const SizedBox(width: 14),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.merchant ?? (isIncome ? 'Pemasukan' : (isExpense ? 'Pengeluaran' : 'Transfer')),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$accountName • ${timeFormat.format(t.transactionDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '$sign${currencyFormat.format(t.amount)}',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isIncome ? AppTheme.income : (isExpense ? AppTheme.expense : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 12),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap + untuk mencatat transaksi pertama',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}
