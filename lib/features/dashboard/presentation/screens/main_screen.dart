import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/screens/home_screen.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:nyatet_pesse/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/history_screen.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/scanner_screen.dart';
import 'package:nyatet_pesse/features/reports/presentation/screens/stats_screen.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/recurring_controller.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabAnimController;
  late Animation<double> _fabAnim;

  static const _navItems = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Beranda'),
    _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Riwayat'),
    _NavItem(Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Scan'),
    _NavItem(Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Akun'),
    _NavItem(Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Statistik'),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnim = CurvedAnimation(parent: _fabAnimController, curve: Curves.easeOut);
    _fabAnimController.forward();

    Future.microtask(() {
      ref.read(recurringControllerProvider.notifier).processDueTransactions();
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final showFab = _currentIndex == 0 || _currentIndex == 1;

    return Scaffold(
      // IndexedStack menjaga state tiap tab tetap hidup (scroll, filter,
      // input setengah jadi) — tidak di-rebuild saat pindah nav.
      // KECUALI tab Scan: di-mount kondisional agar kamera tidak menyala
      // terus di belakang layar (boros baterai + indikator privasi nyala).
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const HistoryScreen(),
          _currentIndex == 2 ? const ScannerScreen() : const SizedBox.shrink(),
          const AccountsScreen(),
          const StatsScreen(),
        ],
      ),
      floatingActionButton: showFab
          ? ScaleTransition(
              scale: _fabAnim,
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                  );
                },
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: List.generate(_navItems.length, (i) {
                  if (i == 2) {
                    return Expanded(child: _buildCenterButton(i));
                  }
                  return Expanded(child: _buildNavTile(i));
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile(int index) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabChanged(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? item.activeIcon : item.inactiveIcon,
              size: 22,
              color: isSelected ? AppTheme.primary : Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.primary : Theme.of(context).hintColor,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton(int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabChanged(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 22,
              color: isSelected ? Colors.white : Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.primary : Theme.of(context).hintColor,
            ),
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}
