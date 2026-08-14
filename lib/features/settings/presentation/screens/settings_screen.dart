import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.background,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
              ),
            ),
            title: const Text(
              'Pengaturan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.3),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Group 1: Keamanan
                _SectionHeader(title: 'Keamanan'),
                const SizedBox(height: 8),
                _SettingsCard(
                  items: [
                    _SettingsItem(
                      icon: Icons.shield_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Keamanan & Privasi',
                      subtitle: 'PIN, biometrik, dan app lock',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Group 2: Transaksi
                _SectionHeader(title: 'Transaksi'),
                const SizedBox(height: 8),
                _SettingsCard(
                  items: [
                    _SettingsItem(
                      icon: Icons.grid_view_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Manajemen Kategori',
                      subtitle: 'Tambah atau ubah kategori',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                    ),
                    _SettingsItem(
                      icon: Icons.autorenew_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Pengeluaran Rutin',
                      subtitle: 'Kelola tagihan dan transaksi otomatis',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen())),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Group 3: Integrasi & Data
                _SectionHeader(title: 'Integrasi & Data'),
                const SizedBox(height: 8),
                _SettingsCard(
                  items: [
                    _SettingsItem(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Pengaturan Notifikasi',
                      subtitle: 'Sumber bank dan e-wallet',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                    ),
                    _SettingsItem(
                      icon: Icons.download_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Ekspor Data (CSV)',
                      subtitle: 'Simpan riwayat ke Excel/Spreadsheet',
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
                  ],
                ),

                const SizedBox(height: 40),

                // Version info
                Center(
                  child: Text(
                    'NyatetPesse • v1.0.0',
                    style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 66,
          color: AppTheme.borderColor.withValues(alpha: 0.5),
        ),
        itemBuilder: (_, i) => _buildItem(context, items[i]),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _SettingsItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
