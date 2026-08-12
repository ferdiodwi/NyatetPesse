import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/reports/presentation/providers/reports_provider.dart';
import 'package:nyatet_pesse/features/reports/presentation/screens/budget_screen.dart';

class BudgetSummaryWidget extends ConsumerWidget {
  const BudgetSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsControllerProvider);

    if (state.isLoading || state.budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find the budget that is closest to being overbudget
    final criticalBudgets = List.of(state.budgets)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    
    final topBudget = criticalBudgets.first;
    final isOver = topBudget.isOverBudget;
    final pct = topBudget.percentage > 1.0 ? 1.0 : topBudget.percentage;
    final colorStr = topBudget.category.color ?? 'FF2196F3';
    final baseColor = Color(int.parse(colorStr, radix: 16));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Peringatan Anggaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetScreen()),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, color: baseColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      topBudget.category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOver ? Colors.red : (pct > 0.8 ? Colors.orange : Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.grey[300],
                  color: isOver ? Colors.red : (pct > 0.8 ? Colors.orange : baseColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
