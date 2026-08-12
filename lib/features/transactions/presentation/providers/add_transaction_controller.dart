import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';

final transactionTypeProvider = StateProvider<String>((ref) => 'EXPENSE');

final selectedAccountProvider = StateProvider<Account?>((ref) => null);
final selectedCategoryProvider = StateProvider<Category?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class AddTransactionController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AddTransactionController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> saveTransaction({
    required double amount,
    required String? merchant,
    required String? note,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final type = _ref.read(transactionTypeProvider);
      final account = _ref.read(selectedAccountProvider);
      final category = _ref.read(selectedCategoryProvider);
      final date = _ref.read(selectedDateProvider);
      
      if (account == null) {
        throw Exception("Pilih akun terlebih dahulu");
      }
      
      if (category == null && type != 'TRANSFER') {
        throw Exception("Pilih kategori terlebih dahulu");
      }
      
      final repo = _ref.read(transactionRepositoryProvider);
      
      final companion = TransactionsCompanion.insert(
        type: type,
        amount: amount,
        transactionDate: date,
        source: 'manual',
        accountId: account.id,
        categoryId: drift.Value(category?.id),
        merchant: drift.Value(merchant),
        description: drift.Value(note),
        createdAt: DateTime.now(),
        updatedAt: drift.Value(DateTime.now()),
      );
      
      await repo.addTransaction(companion);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final addTransactionControllerProvider = StateNotifierProvider<AddTransactionController, AsyncValue<void>>((ref) {
  return AddTransactionController(ref);
});

// Streams for bottom sheets
final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAllAccounts();
});

final categoriesStreamProvider = StreamProvider.family<List<Category>, String>((ref, type) {
  return ref.watch(categoryRepositoryProvider).watchCategoriesByType(type);
});
