import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/inbox_controller.dart';

import 'package:nyatet_pesse/features/transactions/presentation/screens/add_transaction_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxItemsProvider);
    final inboxController = ref.watch(inboxControllerProvider);
    
    // We access the controller here just to make sure the provider is alive and listening to notifications
    // A better place for global listeners is in a root widget or main provider, but this works for MVP.
    
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Inbox'),
      ),
      body: inboxAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada transaksi otomatis',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Notifikasi dari bank/e-wallet Anda akan muncul di sini',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              
              double? parsedAmount;
              String? parsedType;
              
              if (item.extractedData != null) {
                try {
                  final data = jsonDecode(item.extractedData!);
                  parsedAmount = data['amount'] as double?;
                  parsedType = data['type'] as String?;
                } catch (_) {}
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.sourceApp ?? 'Unknown App',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM HH:mm').format(item.detectedAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.rawText,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      if (parsedAmount != null)
                        Row(
                          children: [
                            Icon(
                              parsedType == 'INCOME' ? Icons.arrow_downward : Icons.arrow_upward,
                              color: parsedType == 'INCOME' ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currencyFormat.format(parsedAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Nominal tidak terdeteksi otomatis',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => inboxController.rejectItem(item.id),
                            child: const Text('Tolak'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddTransactionScreen(
                                    initialAmount: parsedAmount,
                                    initialType: parsedType,
                                    initialNote: item.rawText.replaceAll('\n', ' '), // Put raw text in note for context
                                    onSaved: () {
                                      // When successfully saved, update the status in Inbox
                                      inboxController.confirmItem(item.id);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: const Text('Konfirmasi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
