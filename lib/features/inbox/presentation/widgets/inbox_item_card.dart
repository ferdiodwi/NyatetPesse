import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      } catch (e) {
        print('Error decoding extractedData: $e');
      }
    }

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      parsed?.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                      color: parsed?.type == 'income' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.sourceApp ?? 'Notifikasi',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM HH:mm').format(item.detectedAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (parsed != null) ...[
              Text(
                parsed.merchant ?? 'Merchant Tidak Diketahui',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(parsed.amount),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: parsed.confidenceScore,
                backgroundColor: Colors.grey[200],
                color: parsed.confidenceScore > 0.8 ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 4),
              Text(
                'Akurasi: ${(parsed.confidenceScore * 100).toInt()}%',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ] else ...[
              Text(
                item.rawText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gagal memproses transaksi otomatis.',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ref.read(inboxControllerProvider.notifier).rejectTransaction(item);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final controller = ref.read(inboxControllerProvider.notifier);
                    final accounts = await ref.read(accountRepositoryProvider).watchAllAccounts().first;
                    if (accounts.isNotEmpty) {
                      controller.confirmTransaction(
                        item,
                        accountId: accounts.first.id,
                        amount: parsed?.amount ?? 0,
                        type: parsed?.type ?? 'expense',
                        merchant: parsed?.merchant,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Anda belum memiliki Akun/Dompet!')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
