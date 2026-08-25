import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/reports/domain/budget_pace.dart';
import 'package:nyatet_pesse/features/reports/presentation/providers/reports_provider.dart';

/// Kartu pace budget harian: "sisa budget ÷ hari tersisa = aman per hari".
/// Angka yang paling berguna dicek tiap pagi.
class BudgetPaceCard extends ConsumerWidget {
  const BudgetPaceCard({super.key});

  static final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsControllerProvider);
    final budgets = reports.budgets;
    if (budgets.isEmpty) return const SizedBox.shrink();

    final totalLimit = budgets.fold<double>(0, (s, b) => s + b.limit);
    final totalSpent = budgets.fold<double>(0, (s, b) => s + b.spent);
    final pace = BudgetPace(
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      now: DateTime.now(),
    );

    final overBudget = pace.overBudget;
    final accent = overBudget ? AppTheme.expense : AppTheme.primary;

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
              Icon(Icons.speed_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                'Pace Budget Bulan Ini',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${(pace.progress * 100).toInt()}% terpakai',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pace.progress,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            overBudget
                ? 'Budget terlampaui ${_currency.format(pace.remaining.abs())} — saatnya evaluasi.'
                : 'Sisa ${_currency.format(pace.remaining)} ÷ ${pace.daysLeft} hari = aman ${_currency.format(pace.safePerDay)}/hari',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: overBudget
                  ? AppTheme.expense
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: overBudget ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
