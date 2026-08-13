import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/account_horizontal_list.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/ai_detection_banner.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/widgets/recent_transactions_list.dart';
import 'package:nyatet_pesse/features/reports/presentation/widgets/budget_summary_widget.dart';
import 'package:nyatet_pesse/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:nyatet_pesse/features/inbox/presentation/providers/inbox_controller.dart';
import 'package:nyatet_pesse/features/settings/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingItems = ref.watch(pendingInboxProvider).valueOrNull ?? [];
    final unreadCount = pendingItems.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat pagi,',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Ferdio',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount.toString()),
              child: const Icon(Icons.notifications_active_outlined),
            ),
            tooltip: 'Transaction Inbox',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InboxScreen()),
              );
            },
            color: Theme.of(context).colorScheme.onSurface,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingInboxProvider);
          // Assuming accountsStreamProvider is used in children
          // We just add a small delay to simulate network/db refresh
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
        children: const [
          BalanceCard(),
          SizedBox(height: 24),
          AccountHorizontalList(),
          SizedBox(height: 24),
          AiDetectionBanner(),
          SizedBox(height: 24),
          BudgetSummaryWidget(),
          SizedBox(height: 24),
          RecentTransactionsList(),
          SizedBox(height: 80), // Space for FAB
        ],
      ), // This closes ListView
      ), // This closes RefreshIndicator
    ); // This closes Scaffold
  }
}
