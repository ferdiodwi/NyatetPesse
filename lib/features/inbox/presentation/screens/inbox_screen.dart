import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/inbox/presentation/providers/inbox_controller.dart';
import 'package:nyatet_pesse/features/inbox/presentation/widgets/inbox_item_card.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingItemsAsync = ref.watch(pendingInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kotak Masuk Transaksi'),
        elevation: 0,
      ),
      body: pendingItemsAsync.when(
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pendingInboxProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: items.isEmpty 
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada transaksi baru.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InboxItemCard(item: item);
                  },
                ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Terjadi kesalahan: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
