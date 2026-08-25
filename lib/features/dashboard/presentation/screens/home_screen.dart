import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:nyatet_pesse/features/inbox/presentation/providers/inbox_controller.dart';
import 'package:nyatet_pesse/features/reports/presentation/providers/reports_provider.dart';
import 'package:nyatet_pesse/features/settings/presentation/screens/settings_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/settings_provider.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/account_horizontal_list.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/battery_optimization_banner.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/budget_pace_card.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/upcoming_bills_card.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/recent_transactions_list.dart';
import 'package:nyatet_pesse/features/reports/presentation/widgets/budget_summary_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingItems = ref.watch(pendingInboxProvider).valueOrNull ?? [];
    final unreadCount = pendingItems.length;
    final userName = ref.watch(userNameProvider);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingInboxProvider);
          ref.invalidate(accountsStreamProvider);
          await ref.read(reportsControllerProvider.notifier).loadData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Custom Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(context, ref, greeting, unreadCount, userName),
            ),

            // ── Content ───────────────────────────────────────────────────
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  BalanceCard(),
                  SizedBox(height: 24),
                  AccountHorizontalList(),
                  SizedBox(height: 20),
                  BatteryOptimizationBanner(),
                  SizedBox(height: 20),
                  BudgetSummaryWidget(),
                  SizedBox(height: 20),
                  BudgetPaceCard(),
                  SizedBox(height: 20),
                  UpcomingBillsCard(),
                  SizedBox(height: 20),
                  RecentTransactionsList(),
                  SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String greeting,
    int unreadCount,
    String userName,
  ) {
    final hasName = userName.isNotEmpty;
    final avatarLetter = hasName ? userName[0].toUpperCase() : 'N';
    final displayName = hasName ? '$userName 👋' : 'Selamat datang 👋';

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF000666), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? greeting : 'NyatetPesse',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Notif button
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            badge: unreadCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InboxScreen()),
            ),
          ),
          const SizedBox(width: 8),
          // Settings button
          _HeaderIconButton(
            icon: Icons.settings_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
            ),
            if (badge > 0)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  decoration: BoxDecoration(
                    color: AppTheme.expense,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
