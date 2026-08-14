import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/inbox/domain/models/parsed_transaction.dart';
import 'package:nyatet_pesse/features/inbox/presentation/providers/inbox_controller.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';

class InboxItemCard extends ConsumerWidget {
  final InboxItem item;
  const InboxItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ParsedTransaction? parsed;
    if (item.extractedData != null) {
      try {
        parsed = ParsedTransaction.fromJson(jsonDecode(item.extractedData!));
      } catch (_) {}
    }

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isIncome = parsed?.type == 'income';
    final typeColor = isIncome ? AppTheme.income : AppTheme.expense;
    final typeIcon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    // Shorten package name for display
    String sourceLabel = item.sourceApp ?? 'Notifikasi';
    if (sourceLabel.contains('bankbke') || sourceLabel.contains('seabank')) {
      sourceLabel = 'SeaBank';
    } else if (sourceLabel.contains('dana')) {
      sourceLabel = 'DANA';
    } else if (sourceLabel.contains('ovo')) {
      sourceLabel = 'OVO';
    } else if (sourceLabel.contains('gojek')) {
      sourceLabel = 'GoPay';
    } else if (sourceLabel.contains('shopee')) {
      sourceLabel = 'ShopeePay';
    } else if (sourceLabel.contains('bca')) {
      sourceLabel = 'BCA';
    } else if (sourceLabel.contains('mandiri')) {
      sourceLabel = 'Mandiri';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sourceLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(item.detectedAt),
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Confidence badge
                if (parsed != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: parsed.confidenceScore > 0.8
                          ? AppTheme.income.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(parsed.confidenceScore * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: parsed.confidenceScore > 0.8 ? AppTheme.income : Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),

          // ── Transaction detail ───────────────────────────────────────────
          if (parsed != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Merchant', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          parsed.merchant ?? '—',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Nominal', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(parsed.amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.rawText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Gagal memproses otomatis',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.5)),

          // ── Action buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => ref.read(inboxControllerProvider.notifier).rejectTransaction(item),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.expense,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Hapus', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      final controller = ref.read(inboxControllerProvider.notifier);
                      final accounts = await ref.read(accountRepositoryProvider).watchAllAccounts().first;
                      final matchedAccountId = await _findOrCreateAccountId(context, ref, accounts, item.sourceApp);

                      if (matchedAccountId != 0 && context.mounted) {
                        controller.confirmTransaction(
                          item,
                          accountId: matchedAccountId,
                          amount: parsed?.amount ?? 0,
                          type: parsed?.type ?? 'expense',
                          merchant: parsed?.merchant,
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Anda belum memiliki Akun/Dompet sama sekali!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.income,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Simpan Transaksi', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _findOrCreateAccountId(BuildContext context, WidgetRef ref, List<Account> accounts, String? sourceApp) async {
    if (sourceApp == null) return accounts.isNotEmpty ? accounts.first.id : 0;

    final sourceLower = sourceApp.toLowerCase();
    List<String> keywords = [];
    String? defaultName;

    if (sourceLower.contains('seabank') || sourceLower.contains('bankbke')) {
      keywords = ['seabank', 'sea bank', 'bke'];
      defaultName = 'SeaBank';
    } else if (sourceLower.contains('dana')) {
      keywords = ['dana'];
      defaultName = 'DANA';
    } else if (sourceLower.contains('ovo')) {
      keywords = ['ovo'];
      defaultName = 'OVO';
    } else if (sourceLower.contains('gojek')) {
      keywords = ['gopay', 'go-pay', 'gojek'];
      defaultName = 'GoPay';
    } else if (sourceLower.contains('shopee')) {
      keywords = ['shopeepay', 'shopee pay', 'spay'];
      defaultName = 'ShopeePay';
    } else if (sourceLower.contains('bca')) {
      keywords = ['bca'];
      defaultName = 'BCA';
    } else if (sourceLower.contains('mandiri')) {
      keywords = ['mandiri', 'livin'];
      defaultName = 'Mandiri';
    }

    for (final keyword in keywords) {
      for (final account in accounts) {
        if (account.name.toLowerCase().contains(keyword)) return account.id;
      }
    }

    if (defaultName != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Akun $defaultName belum ada. Sistem membuat otomatis!')),
        );
      }
      final repo = ref.read(accountRepositoryProvider);
      final newId = await repo.addAccount(
        AccountsCompanion.insert(
          name: defaultName,
          type: 'E-WALLET',
          currentBalance: Value(0.0),
          createdAt: DateTime.now(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return newId;
    }

    return accounts.isNotEmpty ? accounts.first.id : 0;
  }
}
