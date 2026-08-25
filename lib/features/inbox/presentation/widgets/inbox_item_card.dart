import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/inbox/domain/models/parsed_transaction.dart';
import 'package:nyatet_pesse/features/inbox/domain/services/account_matcher.dart';
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
        color: Theme.of(context).colorScheme.surface,
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(item.detectedAt),
                        style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
          Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
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
                        Text('Merchant', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(
                          parsed.merchant ?? '—',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Nominal', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
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
          Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),

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
                      final match = await AccountMatcher.findOrCreate(
                        ref.read(accountRepositoryProvider),
                        accounts,
                        item.sourceApp,
                      );
                      final matchedAccountId = match.accountId;
                      if (match.created && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Akun ${match.createdName} belum ada. Sistem membuat otomatis!')),
                        );
                      }

                      if (matchedAccountId != 0 && context.mounted) {
                        final result = await controller.confirmTransaction(
                          item,
                          accountId: matchedAccountId,
                          amount: parsed?.amount ?? 0,
                          type: parsed?.type ?? 'expense',
                          merchant: parsed?.merchant,
                        );

                        // Deteksi duplikat → konfirmasi pengguna.
                        if (result.isDuplicate && context.mounted) {
                          final forceSave = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Row(
                                children: [
                                  Icon(Icons.copy_all_rounded, color: Colors.orange, size: 22),
                                  SizedBox(width: 10),
                                  Text('Kemungkinan Duplikat', style: TextStyle(fontSize: 17)),
                                ],
                              ),
                              content: Text(
                                'Ada ${result.duplicateCount} transaksi serupa (nominal & akun sama, ±1 hari) sudah tercatat. Simpan tetap?',
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Simpan Tetap'),
                                ),
                              ],
                            ),
                          );

                          if (forceSave == true) {
                            await controller.confirmTransaction(
                              item,
                              accountId: matchedAccountId,
                              amount: parsed?.amount ?? 0,
                              type: parsed?.type ?? 'expense',
                              merchant: parsed?.merchant,
                              force: true,
                            );
                          }
                        }
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


}
