/// Perhitungan pace budget bulanan — kelas murni agar mudah diuji.
class BudgetPace {
  final double totalLimit;
  final double totalSpent;
  final DateTime now;

  const BudgetPace({
    required this.totalLimit,
    required this.totalSpent,
    required this.now,
  });

  double get remaining => totalLimit - totalSpent;

  bool get overBudget => remaining <= 0;

  double get progress =>
      totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

  /// Jumlah hari tersisa di bulan berjalan (termasuk hari ini).
  int get daysLeft {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return daysInMonth - now.day + 1;
  }

  /// Alokasi aman per hari bila sisa budget dibagi rata sampai akhir bulan.
  double get safePerDay => overBudget ? 0.0 : remaining / daysLeft;
}
