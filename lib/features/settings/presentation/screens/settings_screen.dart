import 'package:flutter/material.dart';
import 'package:nyatet_pesse/features/categories/presentation/screens/categories_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:nyatet_pesse/features/security/presentation/screens/security_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
