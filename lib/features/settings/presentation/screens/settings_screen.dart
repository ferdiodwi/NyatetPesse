import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/categories/presentation/screens/categories_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:nyatet_pesse/features/security/presentation/screens/security_settings_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/export_provider.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/recurring_transactions_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Keamanan & Privasi'),
            subtitle: const Text('PIN dan biometrik (App Lock)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manajemen Kategori'),
            subtitle: const Text('Tambah atau ubah kategori transaksi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: const Text('Pengeluaran Rutin'),
            subtitle: const Text('Kelola tagihan dan transaksi otomatis'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecurringTransactionsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Pengaturan Notifikasi'),
            subtitle: const Text('Atur sumber aplikasi bank dan e-wallet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Ekspor Data (CSV)'),
            subtitle: const Text('Simpan riwayat transaksi ke Excel'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menyiapkan file ekspor...')),
                );
                await ref.read(exportServiceProvider).exportTransactionsToCsv();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengekspor: $e')),
                  );
                }
              }
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
