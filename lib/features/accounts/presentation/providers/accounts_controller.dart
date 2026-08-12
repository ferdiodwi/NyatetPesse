import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';

class AccountsController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AccountsController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> saveAccount({
    required String name,
    required String type, // 'Bank', 'E-Wallet', 'Cash'
    required double initialBalance,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final repo = _ref.read(accountRepositoryProvider);
      
      final companion = AccountsCompanion.insert(
        name: name,
        type: type,
        initialBalance: drift.Value(initialBalance),
        currentBalance: drift.Value(initialBalance),
        isActive: const drift.Value(true),
        createdAt: DateTime.now(),
        updatedAt: drift.Value(DateTime.now()),
      );
      
      await repo.addAccount(companion);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final accountsControllerProvider = StateNotifierProvider<AccountsController, AsyncValue<void>>((ref) {
  return AccountsController(ref);
});

// Reuse accountsStreamProvider from AddTransactionController for global account reading
// Or we can define it here if we refactor, but for now we can rely on the existing one.
