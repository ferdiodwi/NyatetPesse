import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
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
  );
});

class InboxController extends StateNotifier<AsyncValue<void>> {
  final InboxRepository _inboxRepo;
  final TransactionRepository _transactionRepo;

  InboxController(this._inboxRepo, this._transactionRepo) : super(const AsyncValue.data(null));

  /// Konfirmasi item inbox menjadi transaksi.
  ///
  /// Update saldo ditangani penuh oleh [TransactionRepository.addTransaction]
  /// (dengan normalisasi tipe) — controller ini tidak mengubah saldo lagi
  /// agar tidak terjadi penghitungan ganda.
  ///
  /// Bila terdeteksi duplikat dan [force] false, mengembalikan
  /// [ConfirmResult.duplicate] tanpa menyimpan apa pun.
  Future<ConfirmResult> confirmTransaction(InboxItem item, {
    required int accountId,
    int? categoryId,
    required double amount,
    required String type,
    String? merchant,
    bool force = false,
  }) async {
    // 0. Deteksi duplikat: transaksi serupa (akun + nominal + ±1 hari).
    if (!force) {
      final duplicates = await _transactionRepo.findPotentialDuplicates(
        accountId: accountId,
        amount: amount,
      );
      if (duplicates.isNotEmpty) {
        return ConfirmResult.duplicate(duplicates.length);
      }
    }

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

      // 2. Insert Transaction + update saldo (satu sumber kebenaran).
      await _transactionRepo.addTransaction(txCompanion);

      // 3. Update Inbox Status
      await _inboxRepo.updateInboxItemStatus(item.id, 'confirmed');

      state = const AsyncValue.data(null);
      return const ConfirmResult.saved();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return ConfirmResult.failure;
    }
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

/// Hasil konfirmasi item inbox.
class ConfirmResult {
  final bool saved;
  final int duplicateCount;

  const ConfirmResult._(this.saved, this.duplicateCount);

  const ConfirmResult.saved() : this._(true, 0);
  const ConfirmResult.duplicate(int count) : this._(false, count);
  static const ConfirmResult failure = ConfirmResult._(false, 0);

  bool get isDuplicate => !saved && duplicateCount > 0;
}
