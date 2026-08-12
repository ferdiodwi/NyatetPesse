import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/features/reports/presentation/providers/reports_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final NumberFormat _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  void _showSetBudgetDialog(BuildContext context, Category category, double currentBudget) {
    final TextEditingController controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toInt().toString() : '',
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Budget ${category.name}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Batas Pengeluaran Bulanan',
              prefixText: 'Rp ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            if (currentBudget > 0)
              TextButton(
                onPressed: () {
                   ref.read(reportsControllerProvider.notifier).setBudget(category.id, 0);
                   Navigator.pop(context);
                },
                child: const Text('Hapus Budget', style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text) ?? 0.0;
                ref.read(reportsControllerProvider.notifier).setBudget(category.id, val);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showAddBudgetSheet(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final categories = await (db.select(db.categories)..where((t) => t.type.equals('EXPENSE') & t.isActive.equals(true))).get();
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Pilih Kategori untuk Dianggarkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...categories.map((cat) {
              Color color = Color(int.parse(cat.color ?? 'FF2196F3', radix: 16));
              return ListTile(
                leading: Icon(Icons.category, color: color),
                title: Text(cat.name),
                onTap: () {
                  Navigator.pop(context);
                  _showSetBudgetDialog(context, cat, 0);
                },
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran (Budget)'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Belum ada anggaran yang dibuat.'),
                      const Text('Tambahkan budget agar pengeluaran Anda terkontrol.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.budgets.length,
                  itemBuilder: (context, index) {
                    final progress = state.budgets[index];
                    final isOver = progress.isOverBudget;
                    final pct = progress.percentage > 1.0 ? 1.0 : progress.percentage;
                    final colorStr = progress.category.color ?? 'FF2196F3';
                    final baseColor = Color(int.parse(colorStr, radix: 16));
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _showSetBudgetDialog(context, progress.category, progress.limit),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.category, color: baseColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    progress.category.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(pct * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isOver ? Colors.red : (pct > 0.8 ? Colors.orange : Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                                backgroundColor: Colors.grey[200],
                                color: isOver ? Colors.red : (pct > 0.8 ? Colors.orange : baseColor),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Terpakai', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(
                                        _formatter.format(progress.spent),
                                        style: TextStyle(fontWeight: FontWeight.bold, color: isOver ? Colors.red : null),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Dari Anggaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(
                                        _formatter.format(progress.limit),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Buat Anggaran'),
      ),
    );
  }
}
