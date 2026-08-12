import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:intl/intl.dart';

class AccountHorizontalList extends ConsumerWidget {
  const AccountHorizontalList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(isBalanceVisibleProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final accounts = [
      {'name': 'BCA', 'balance': 4500000, 'icon': Icons.account_balance, 'color': const Color(0xFFe0e0ff), 'iconColor': const Color(0xFF000666)},
      {'name': 'DANA', 'balance': 1250000, 'icon': Icons.account_balance_wallet, 'color': const Color(0xFFE3F2FD), 'iconColor': const Color(0xFF1565C0)},
      {'name': 'OVO', 'balance': 750000, 'icon': Icons.account_balance_wallet, 'color': const Color(0xFFF3E5F5), 'iconColor': const Color(0xFF6A1B9A)},
      {'name': 'GoPay', 'balance': 500000, 'icon': Icons.account_balance_wallet, 'color': const Color(0xFFE8F5E9), 'iconColor': const Color(0xFF2E7D32)},
      {'name': 'Cash', 'balance': 1750000, 'icon': Icons.payments, 'color': Theme.of(context).colorScheme.surfaceContainerHigh, 'iconColor': Theme.of(context).colorScheme.onSurfaceVariant},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Akun',
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
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: account['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        account['icon'] as IconData,
                        size: 18,
                        color: account['iconColor'] as Color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      account['name'] as String,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVisible ? currencyFormat.format(account['balance']) : 'Rp ••••',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
