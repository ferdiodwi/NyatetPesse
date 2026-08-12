import 'package:drift/drift.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';

class CategoryExpense {
  final Category category;
  final double totalAmount;

  CategoryExpense(this.category, this.totalAmount);
}

class BudgetProgress {
  final Category category;
  final double limit;
  final double spent;

  BudgetProgress(this.category, this.limit, this.spent);

  double get percentage => limit > 0 ? (spent / limit) : 0;
  bool get isOverBudget => spent > limit;
}

class ReportsRepository {
  final AppDatabase _db;

  ReportsRepository(this._db);

  // Get total expense grouped by category for a specific month
  Future<List<CategoryExpense>> getExpensesByCategory(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

    final amountSum = _db.transactions.amount.sum();

    final query = _db.select(_db.transactions).join([
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
    ])
      ..where(_db.transactions.type.equals('EXPENSE') &
          _db.transactions.transactionDate.isBetweenValues(startDate, endDate) &
          _db.transactions.isConfirmed.equals(true))
      ..addColumns([amountSum])
      ..groupBy([_db.categories.id]);

    final result = await query.get();

    return result.map((row) {
      final category = row.readTable(_db.categories);
      final total = row.read(amountSum) ?? 0.0;
      return CategoryExpense(category, total);
    }).toList();
  }

  // Get budget progress for all budgeted categories in a specific month
  Future<List<BudgetProgress>> getBudgetProgress(int year, int month) async {
    // 1. Get all budgets for this month
    final budgetsQuery = _db.select(_db.budgetSettings).join([
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.budgetSettings.categoryId)),
    ])..where(_db.budgetSettings.year.equals(year) & _db.budgetSettings.month.equals(month));

    final budgetRows = await budgetsQuery.get();

    if (budgetRows.isEmpty) return [];

    // 2. Get expenses for the month
    final expenses = await getExpensesByCategory(year, month);
    final expenseMap = {for (var e in expenses) e.category.id: e.totalAmount};

    // 3. Combine
    return budgetRows.map((row) {
      final budget = row.readTable(_db.budgetSettings);
      final category = row.readTable(_db.categories);
      final spent = expenseMap[category.id] ?? 0.0;
      
      return BudgetProgress(category, budget.amount, spent);
    }).toList();
  }

  Future<void> setBudget(int categoryId, double amount, int year, int month) async {
    // Check if budget exists
    final existing = await (_db.select(_db.budgetSettings)
          ..where((t) => t.categoryId.equals(categoryId) & t.year.equals(year) & t.month.equals(month)))
        .getSingleOrNull();

    if (existing != null) {
      if (amount <= 0) {
        // Delete if amount is 0
        await (_db.delete(_db.budgetSettings)..where((t) => t.id.equals(existing.id))).go();
      } else {
        // Update
        await (_db.update(_db.budgetSettings)..where((t) => t.id.equals(existing.id))).write(
          BudgetSettingsCompanion(
            amount: Value(amount),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    } else {
      if (amount > 0) {
        // Insert
        await _db.into(_db.budgetSettings).insert(
          BudgetSettingsCompanion.insert(
            categoryId: categoryId,
            amount: amount,
            year: year,
            month: month,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
  }
}
