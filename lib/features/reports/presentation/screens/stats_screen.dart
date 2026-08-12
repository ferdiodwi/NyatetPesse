import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/features/reports/presentation/providers/reports_provider.dart';
import 'package:nyatet_pesse/features/reports/presentation/screens/budget_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _touchedIndex = -1;

  String _getMonthName(int month) {
    return DateFormat('MMMM', 'id_ID').format(DateTime(2024, month));
  }

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Pilih Periode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('Bulan Ini (${_getMonthName(now.month)})'),
                onTap: () {
                  ref.read(reportsControllerProvider.notifier).setPeriod(now.year, now.month);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Bulan Lalu (${_getMonthName(now.month - 1 > 0 ? now.month - 1 : 12)})'),
                onTap: () {
                  int year = now.month - 1 > 0 ? now.year : now.year - 1;
                  int month = now.month - 1 > 0 ? now.month - 1 : 12;
                  ref.read(reportsControllerProvider.notifier).setPeriod(year, month);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsControllerProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showMonthPicker(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Statistik ${_getMonthName(state.selectedMonth)}'),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Budget',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              );
            },
          )
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.expenses.isEmpty
              ? const Center(child: Text('Belum ada pengeluaran di bulan ini.'))
              : ListView(
                  children: [
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 60,
                              sections: _generatePieSections(state),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Total Pengeluaran', style: TextStyle(color: Colors.grey)),
                              Text(
                                formatter.format(state.expenses.fold(0.0, (sum, item) => sum + item.totalAmount)),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Rincian Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    ...state.expenses.map((expense) {
                      Color color = Color(int.parse(expense.category.color ?? 'FF2196F3', radix: 16));
                      double percentage = (expense.totalAmount / state.expenses.fold(0.0, (sum, item) => sum + item.totalAmount)) * 100;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(Icons.category, color: color), // Placeholder icon
                        ),
                        title: Text(expense.category.name),
                        subtitle: Text('${percentage.toStringAsFixed(1)}%'),
                        trailing: Text(
                          formatter.format(expense.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

  List<PieChartSectionData> _generatePieSections(ReportsState state) {
    return List.generate(state.expenses.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 0.0;
      final radius = isTouched ? 60.0 : 50.0;
      final expense = state.expenses[i];
      Color color = Color(int.parse(expense.category.color ?? 'FF2196F3', radix: 16));

      return PieChartSectionData(
        color: color,
        value: expense.totalAmount,
        title: isTouched ? '${((expense.totalAmount / state.expenses.fold(0.0, (sum, item) => sum + item.totalAmount)) * 100).toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
        ),
      );
    });
  }
}
