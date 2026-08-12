import 'package:flutter/material.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/screens/home_screen.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:nyatet_pesse/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/history_screen.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/scanner_screen.dart';
import 'package:nyatet_pesse/features/reports/presentation/screens/stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const HistoryScreen(),
    const ScannerScreen(),
    const AccountsScreen(), // Budget/Accounts Tab
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      // We will move the "Tambah Transaksi" FAB to the top or keep it as an action.
      // But for now, we will place it slightly above the bottom nav bar, or remove it 
      // if the user wants Scanner to be the primary action. 
      // Let's keep it at endFloat.
      floatingActionButton: _currentIndex == 1 || _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildNavItem(0, Icons.home_filled, Icons.home_outlined, 'Beranda'),
                    _buildNavItem(1, Icons.receipt_long, Icons.receipt_long_outlined, 'Riwayat'),
                    const SizedBox(width: 60), // Space for the center item
                    _buildNavItem(3, Icons.account_balance_wallet, Icons.account_balance_wallet_outlined, 'Akun'),
                    _buildNavItem(4, Icons.query_stats, Icons.query_stats_outlined, 'Statistik'),
                  ],
                ),
                Positioned(
                  top: -20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary, // Warna biru dominan
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                              color: _currentIndex == 2
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? primaryColor : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
