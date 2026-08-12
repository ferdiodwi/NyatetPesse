import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/data/repositories/reports_repository.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';

class ReportsState {
  final bool isLoading;
  final List<CategoryExpense> expenses;
  final List<BudgetProgress> budgets;
  final int selectedMonth;
  final int selectedYear;

  ReportsState({
    this.isLoading = true,
    this.expenses = const [],
    this.budgets = const [],
    required this.selectedMonth,
    required this.selectedYear,
  });

  ReportsState copyWith({
    bool? isLoading,
    List<CategoryExpense>? expenses,
    List<BudgetProgress>? budgets,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      budgets: budgets ?? this.budgets,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

class ReportsController extends StateNotifier<ReportsState> {
  final ReportsRepository _repo;

  ReportsController(this._repo)
      : super(ReportsState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        )) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    
    final expenses = await _repo.getExpensesByCategory(state.selectedYear, state.selectedMonth);
    // Sort expenses by amount descending
    expenses.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final budgets = await _repo.getBudgetProgress(state.selectedYear, state.selectedMonth);

    state = state.copyWith(
      isLoading: false,
      expenses: expenses,
      budgets: budgets,
    );
  }

  void setPeriod(int year, int month) {
    state = state.copyWith(selectedYear: year, selectedMonth: month);
    loadData();
  }

  Future<void> setBudget(int categoryId, double amount) async {
    await _repo.setBudget(categoryId, amount, state.selectedYear, state.selectedMonth);
    loadData();
  }
}

final reportsControllerProvider = StateNotifierProvider<ReportsController, ReportsState>((ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  return ReportsController(repo);
});
