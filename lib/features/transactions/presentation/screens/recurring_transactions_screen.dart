import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/recurring_controller.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/add_transaction_controller.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddRecurringSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(recurringTransactionsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran Rutin'),
      ),
      body: asyncData.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.autorenew, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Belum ada transaksi rutin.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isExpense = item.type == 'EXPENSE';
              
              return Card(
                child: SwitchListTile(
                  title: Text(
                    item.merchant ?? 'Tanpa Merchant',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isExpense ? '- ' : '+ '}${currencyFormat.format(item.amount)}',
                        style: TextStyle(
                          color: isExpense ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Siklus: ${item.interval.toUpperCase()}'),
                      Text('Jatuh tempo berikutnya: ${dateFormat.format(item.nextDate)}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  value: item.isActive,
                  onChanged: (val) {
                    ref.read(recurringControllerProvider.notifier).toggleActive(item.id, val);
                  },
                  secondary: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      ref.read(recurringControllerProvider.notifier).deleteRecurring(item.id);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet();

  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  String _interval = 'monthly';
  DateTime _nextDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(selectedAccountProvider);
    final isProcessing = ref.watch(recurringControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tambah Transaksi Rutin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(labelText: 'Nama Tagihan / Merchant', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _interval,
            decoration: const InputDecoration(labelText: 'Siklus', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Harian')),
              DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
              DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _interval = val);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isProcessing ? null : () async {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0 || account == null) return;
              
              await ref.read(recurringControllerProvider.notifier).addRecurring(
                type: 'EXPENSE',
                amount: amount,
                accountId: account.id,
                merchant: _merchantController.text,
                interval: _interval,
                nextDate: _nextDate,
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: isProcessing ? const CircularProgressIndicator() : const Text('Simpan'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
