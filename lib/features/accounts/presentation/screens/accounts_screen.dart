import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';
import 'package:nyatet_pesse/features/accounts/presentation/widgets/add_account_bottom_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (accounts) {
          final totalBalance = accounts.fold<double>(0, (sum, acc) => sum + acc.currentBalance);

          return CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(context, ref, isVisible, totalBalance, accounts.length, currencyFormat),
              ),

              // ── Section Title + Add Button ─────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Semua Akun',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => const AddAccountBottomSheet(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Tambah',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Account Cards ─────────────────────────────────────────────
              if (accounts.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.textHint),
                        SizedBox(height: 16),
                        Text('Belum ada akun', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                        SizedBox(height: 6),
                        Text('Tap "Tambah" untuk menambah akun pertama', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.55,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _AccountCard(
                        account: accounts[index],
                        isVisible: isVisible,
                        currencyFormat: currencyFormat,
                      ),
                      childCount: accounts.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool isVisible,
    double totalBalance,
    int accountCount,
    NumberFormat currencyFormat,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF000666), Color(0xFF1E3A8A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Akun & Dompet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isVisible ? currencyFormat.format(totalBalance) : 'Rp ••••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(isBalanceVisibleProvider.notifier).state = !isVisible,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Total dari $accountCount akun',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final bool isVisible;
  final NumberFormat currencyFormat;

  const _AccountCard({required this.account, required this.isVisible, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig(account.type);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(config.icon, size: 17, color: config.color),
              ),
              const Spacer(),
              Icon(Icons.more_horiz_rounded, size: 18, color: AppTheme.textHint),
            ],
          ),
          const Spacer(),
          Text(
            account.name,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            isVisible ? currencyFormat.format(account.currentBalance) : 'Rp ••••',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: account.currentBalance >= 0 ? AppTheme.income : AppTheme.expense,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  _TypeConfig _getTypeConfig(String type) {
    switch (type.toUpperCase()) {
      case 'BANK':
        return _TypeConfig(Icons.account_balance_rounded, const Color(0xFF3B82F6));
      case 'E-WALLET':
        return _TypeConfig(Icons.account_balance_wallet_rounded, const Color(0xFF8B5CF6));
      case 'CASH':
      default:
        return _TypeConfig(Icons.payments_rounded, AppTheme.income);
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  const _TypeConfig(this.icon, this.color);
}
