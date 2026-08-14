import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:nyatet_pesse/features/inbox/presentation/providers/inbox_controller.dart';
import 'package:nyatet_pesse/features/settings/presentation/screens/settings_screen.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/account_horizontal_list.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/ai_detection_banner.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/balance_card.dart';
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
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingInboxProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Custom Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(context, ref, greeting, unreadCount),
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
                  AiDetectionBanner(),
                  SizedBox(height: 20),
                  BudgetSummaryWidget(),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, String greeting, int unreadCount) {
    return Container(
      color: AppTheme.background,
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
            child: const Center(
              child: Text(
                'F',
                style: TextStyle(
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
                  greeting,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'Ferdio 👋',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
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
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(icon, size: 20, color: AppTheme.textPrimary),
            ),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.expense,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
