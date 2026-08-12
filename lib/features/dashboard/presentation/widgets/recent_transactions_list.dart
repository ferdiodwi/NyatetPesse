import 'package:flutter/material.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
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
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildTransactionItem(
              context: context,
              icon: Icons.local_cafe,
              title: 'Kopi Senja',
              category: 'Makan & Minum',
              account: 'BCA • Hari ini',
              amount: '- Rp 35.000',
              isExpense: true,
            ),
            const Divider(height: 1),
            _buildTransactionItem(
              context: context,
              icon: Icons.shopping_bag,
              title: 'Tokopedia',
              category: 'Belanja',
              account: 'GoPay • Kemarin',
              amount: '- Rp 150.000',
              isExpense: true,
            ),
            const Divider(height: 1),
            _buildTransactionItem(
              context: context,
              icon: Icons.swap_horiz,
              title: 'Transfer dari Budi',
              category: 'Pemasukan',
              account: 'BCA • 2 Agt',
              amount: '+ Rp 500.000',
              isExpense: false,
              isIncome: true,
            ),
            const Divider(height: 1),
            _buildTransactionItem(
              context: context,
              icon: Icons.directions_car,
              title: 'GrabRide',
              category: 'Transportasi',
              account: 'OVO • 1 Agt',
              amount: '- Rp 24.000',
              isExpense: true,
            ),
          ],
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
