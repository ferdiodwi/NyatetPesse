import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/recurring_controller.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/recurring_transactions_screen.dart';

/// Kartu tagihan mendatang: recurring aktif yang jatuh tempo ≤7 hari.
class UpcomingBillsCard extends ConsumerWidget {
  const UpcomingBillsCard({super.key});

  static final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String _labelFor(DateTime nextDate) {
    final today = DateTime.now();
    final days = DateTime(nextDate.year, nextDate.month, nextDate.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (days <= 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    return '$days hari lagi';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(upcomingBillsProvider);
    final bills = billsAsync.valueOrNull ?? const <RecurringTransaction>[];
    if (bills.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 18, color: AppTheme.transfer),
              const SizedBox(width: 8),
              Text(
                'Tagihan Mendatang',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RecurringTransactionsScreen()),
                ),
                child: Text(
                  'Lihat semua',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...bills.take(3).map((bill) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.transfer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.autorenew_rounded,
                          size: 15, color: AppTheme.transfer),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.merchant ?? bill.note ?? 'Tagihan rutin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _labelFor(bill.nextDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${bill.type.toLowerCase() == 'expense' ? '-' : '+'}${_currency.format(bill.amount)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: bill.type.toLowerCase() == 'expense'
                            ? AppTheme.expense
                            : AppTheme.income,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
