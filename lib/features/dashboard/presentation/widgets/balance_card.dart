import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/core/widgets/error_retry_widget.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:intl/intl.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(isBalanceVisibleProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final monthName = DateFormat('MMMM', 'id_ID').format(DateTime.now());

    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsStream = ref.watch(transactionRepositoryProvider).watchRecentTransactions(limit: 100);

    return accountsAsync.when(
      loading: () => const _CardSkeleton(),
      error: (e, st) => ErrorRetryWidget(
        message: 'Gagal memuat saldo',
        onRetry: () => ref.invalidate(accountsStreamProvider),
      ),
      data: (accounts) {
        final totalBalance = accounts.fold<double>(0, (sum, acc) => sum + acc.currentBalance);

        return StreamBuilder(
          stream: transactionsStream,
          builder: (context, snapshot) {
            double totalIncome = 0;
            double totalExpense = 0;

            if (snapshot.hasData) {
              final now = DateTime.now();
              for (var t in snapshot.data!) {
                if (t.transactionDate.month == now.month && t.transactionDate.year == now.year) {
                  if (t.type == 'INCOME') totalIncome += t.amount;
                  if (t.type == 'EXPENSE') totalExpense += t.amount;
                }
              }
            }

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF000666), Color(0xFF1E3A8A)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -30,
                    right: -20,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    right: 60,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Total Balance Label ───────────────────────────
                        Row(
                          children: [
                            Text(
                              'Total Saldo',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => ref.read(isBalanceVisibleProvider.notifier).state = !isVisible,
                              child: Icon(
                                isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 16,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${accounts.length} Akun',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ── Balance Amount ────────────────────────────────
                        Text(
                          isVisible ? currencyFormat.format(totalBalance) : 'Rp ••••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Divider ───────────────────────────────────────
                        Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),

                        const SizedBox(height: 20),

                        // ── Income / Expense Summary ─────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                icon: Icons.arrow_downward_rounded,
                                iconColor: AppTheme.income,
                                label: 'Masuk $monthName',
                                value: isVisible ? currencyFormat.format(totalIncome) : '••••',
                                valueColor: AppTheme.income,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withValues(alpha: 0.15),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Expanded(
                              child: _StatItem(
                                icon: Icons.arrow_upward_rounded,
                                iconColor: const Color(0xFFFF6B6B),
                                label: 'Keluar $monthName',
                                value: isVisible ? currencyFormat.format(totalExpense) : '••••',
                                valueColor: const Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000666), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
      ),
    );
  }
}
