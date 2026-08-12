import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';
import 'package:nyatet_pesse/features/accounts/presentation/widgets/add_account_bottom_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (accounts) {
          final totalBalance = accounts.fold<double>(0, (sum, acc) => sum + acc.currentBalance);

          return RefreshIndicator(
            onRefresh: () async {
              // Usually handled by stream, but good for UX
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total Assets Card
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Aset',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isVisible ? currencyFormat.format(totalBalance) : 'Rp ••••••••',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(isBalanceVisibleProvider.notifier).state = !isVisible;
                            },
                            icon: Icon(
                              isVisible ? Icons.visibility : Icons.visibility_off,
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar Akun',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => const AddAccountBottomSheet(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Akun'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Account Grid
                if (accounts.isEmpty)
                   const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada akun')))
                else
                   GridView.builder(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: 2,
                       crossAxisSpacing: 12,
                       mainAxisSpacing: 12,
                       childAspectRatio: 1.5,
                     ),
                     itemCount: accounts.length,
                     itemBuilder: (context, index) {
                       final account = accounts[index];
                       
                       // Determine icon & colors based on type
                       IconData iconData;
                       Color bgColor;
                       Color iconColor;
                       
                       switch (account.type.toUpperCase()) {
                         case 'BANK':
                           iconData = Icons.account_balance;
                           bgColor = Colors.blue.shade50;
                           iconColor = Colors.blue.shade700;
                           break;
                         case 'E-WALLET':
                           iconData = Icons.account_balance_wallet;
                           bgColor = Colors.purple.shade50;
                           iconColor = Colors.purple.shade700;
                           break;
                         case 'CASH':
                         default:
                           iconData = Icons.payments;
                           bgColor = Colors.green.shade50;
                           iconColor = Colors.green.shade700;
                           break;
                       }
                       
                       // Cash can take full width if we want, but let's just make it part of grid
                       return Container(
                         decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.surface,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                         ),
                         padding: const EdgeInsets.all(12),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 Container(
                                   width: 32,
                                   height: 32,
                                   decoration: BoxDecoration(
                                     color: bgColor,
                                     shape: BoxShape.circle,
                                     border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                                   ),
                                   child: Icon(iconData, size: 16, color: iconColor),
                                 ),
                                 const Spacer(),
                                 // Maybe options menu
                                 Icon(Icons.more_vert, size: 16, color: Theme.of(context).colorScheme.outline),
                               ],
                             ),
                             const Spacer(),
                             Text(
                               account.name,
                               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                 fontWeight: FontWeight.w600,
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                             Text(
                               isVisible ? currencyFormat.format(account.currentBalance) : 'Rp ••••',
                               style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                 color: Theme.of(context).colorScheme.onSurfaceVariant,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ],
                         ),
                       );
                     },
                   ),
              ],
            ),
          );
        },
      ),
    );
  }
}
