import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/account_repository.dart';
import 'package:nyatet_pesse/data/repositories/inbox_repository.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/data/repositories/transaction_repository.dart';

final pendingInboxProvider = StreamProvider<List<InboxItem>>((ref) {
  final repo = ref.watch(inboxRepositoryProvider);
  return repo.watchPendingInboxItems();
});

final inboxControllerProvider = StateNotifierProvider<InboxController, AsyncValue<void>>((ref) {
  return InboxController(
    ref.watch(inboxRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
});

class InboxController extends StateNotifier<AsyncValue<void>> {
  final InboxRepository _inboxRepo;
  final TransactionRepository _transactionRepo;
  final AccountRepository _accountRepo;

  InboxController(this._inboxRepo, this._transactionRepo, this._accountRepo) : super(const AsyncValue.data(null));

  Future<void> confirmTransaction(InboxItem item, {
    required int accountId,
    int? categoryId,
    required double amount,
    required String type,
    String? merchant,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Convert to Transaction
      final txCompanion = TransactionsCompanion(
        type: Value(type),
        amount: Value(amount),
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        merchant: Value(merchant),
        description: Value(item.rawText),
        transactionDate: Value(DateTime.now()),
        source: Value(item.source),
        sourceApp: Value(item.sourceApp),
        status: const Value('confirmed'),
        confidenceScore: Value(item.confidenceScore),
        isConfirmed: const Value(true),
        createdAt: Value(DateTime.now()),
      );

      // 2. Insert Transaction
      await _transactionRepo.addTransaction(txCompanion);

      // 3. Update Account Balance
      await _updateAccountBalance(accountId, amount, type);

      // 4. Update Inbox Status
      await _inboxRepo.updateInboxItemStatus(item.id, 'confirmed');

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _updateAccountBalance(int accountId, double amount, String type) async {
    final account = await _accountRepo.getAccountById(accountId);
    
    double newBalance = account.currentBalance;
    if (type == 'income') {
      newBalance += amount;
    } else if (type == 'expense') {
      newBalance -= amount;
    }
    
    await _accountRepo.updateAccount(
      account.copyWith(
        currentBalance: newBalance,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> rejectTransaction(InboxItem item) async {
    state = const AsyncValue.loading();
    try {
      await _inboxRepo.updateInboxItemStatus(item.id, 'rejected');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
