import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/features/categories/presentation/screens/categories_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/backup_provider.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/settings_provider.dart';
import 'package:nyatet_pesse/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:nyatet_pesse/features/security/presentation/screens/security_settings_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/export_provider.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/recurring_transactions_screen.dart';
import 'package:flutter/services.dart';
import 'package:nyatet_pesse/notification/services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditNameSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ref.read(userNameProvider));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.person_rounded, color: Color(0xFF0EA5E9), size: 22),
                SizedBox(width: 10),
                Text(
                  'Nama Pengguna',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 24,
              decoration: const InputDecoration(
                hintText: 'Contoh: Ferdio',
                counterText: '',
              ),
              onSubmitted: (_) => _saveName(sheetContext, ref, controller),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveName(sheetContext, ref, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveName(BuildContext sheetContext, WidgetRef ref, TextEditingController controller) {
    ref.read(userNameProvider.notifier).setName(controller.text);
    Navigator.pop(sheetContext);
  }

  String _themeLabel(ThemeModeSetting mode) {
    switch (mode) {
      case ThemeModeSetting.system:
        return 'Ikuti sistem';
      case ThemeModeSetting.light:
        return 'Terang';
      case ThemeModeSetting.dark:
        return 'Gelap';
    }
  }

  // ── Backup ──────────────────────────────────────────────────────────────────
  Future<String?> _askPassword(
    BuildContext context,
    String title,
    String subtitle,
  ) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: const TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Password backup',
                hintText: 'Minimal 8 karakter',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => ElevatedButton(
              onPressed: value.text.trim().length >= 8
                  ? () => Navigator.pop(dialogContext, value.text.trim())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lanjut'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startBackup(BuildContext context, WidgetRef ref) async {
    final password = await _askPassword(
      context,
      'Password Backup',
      'File backup akan dienkripsi dengan password ini. Jika lupa, backup tidak dapat dibuka kembali.',
    );
    if (password == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membuat file backup...')),
    );

    final result = await ref.read(backupServiceProvider).createBackupFile(password);
    if (!context.mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup gagal: ${result.error}')),
      );
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.filePath!)],
          text: 'Backup database NyatetPesse (terenkripsi)',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan file: $e')),
        );
      }
    }
  }

  // ── Restore ─────────────────────────────────────────────────────────────────
  Future<void> _startRestore(BuildContext context, WidgetRef ref) async {
    // Peringatan
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.expense, size: 22),
            SizedBox(width: 10),
            Text('Pulihkan Backup?', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'Seluruh data saat ini akan DIGANTI dengan isi file backup. Lanjutkan?',
          style: TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expense,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pilih File'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final files = await FilePicker.pickFiles();
    final path = files.isEmpty ? null : files.first.path;
    if (path == null || !context.mounted) return;

    final password = await _askPassword(
      context,
      'Password Backup',
      'Masukkan password yang dipakai saat membuat file backup tersebut.',
    );
    if (password == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memulihkan database...')),
    );

    // Tutup koneksi DB sebelum mengganti file.
    await ref.read(databaseProvider).close();

    final result = await ref
        .read(backupServiceProvider)
        .restoreFrom(File(path), password);
    if (!context.mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore gagal: ${result.error}')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.income, size: 22),
            SizedBox(width: 10),
            Text('Restore Berhasil', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'Database berhasil dipulihkan. Aplikasi akan ditutup — buka kembali untuk memakai data yang dipulihkan.',
          style: TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tutup Aplikasi'),
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ...ThemeModeSetting.values.map(
              (mode) => RadioListTile<ThemeModeSetting>(
                value: mode,
                groupValue: current,
                title: Text(_themeLabel(mode)),
                activeColor: AppTheme.primary,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setMode(value);
                    Navigator.pop(sheetContext);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            title: Text(
              'Pengaturan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.3),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Group 0: Akun
                _SectionHeader(title: 'Akun'),
                const SizedBox(height: 8),
                _SettingsCard(
                  items: [
                    _SettingsItem(
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'Nama Pengguna',
                      subtitle: ref.watch(userNameProvider).isEmpty
                          ? 'Belum diatur — ketuk untuk mengisi'
                          : ref.watch(userNameProvider),
                      onTap: () => _showEditNameSheet(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Group 0.5: Tampilan
                _SectionHeader(title: 'Tampilan'),
                const SizedBox(height: 8),
                _SettingsCard(
                  items: [
                    _SettingsItem(
                      icon: Icons.dark_mode_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Tema',
                      subtitle: _themeLabel(ref.watch(themeModeProvider)),
                      onTap: () => _showThemeSheet(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

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

                const SizedBox(height: 24),

                // Group 4: AI Parser
                _SectionHeader(title: 'Kecerdasan Buatan'),
                const SizedBox(height: 8),
                _SettingsCard(
                  items: [
                    _SettingsItem(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFFEC4899),
                      title: 'Gemini AI Parser',
                      subtitle: 'Tingkatkan akurasi parsing notifikasi',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => _GeminiApiKeySheet(
                          geminiService: ref.read(geminiServiceProvider),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Group 3.5: Backup & Pulihkan
                _SectionHeader(title: 'Backup & Pulihkan'),
                const SizedBox(height: 8),
                _SettingsCard(
                  items: [
                    _SettingsItem(
                      icon: Icons.backup_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'Backup Database',
                      subtitle: 'File terenkripsi — simpan ke Drive/penyimpanan',
                      onTap: () => _startBackup(context, ref),
                    ),
                    _SettingsItem(
                      icon: Icons.restore_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Pulihkan dari Backup',
                      subtitle: 'Ganti data saat ini dengan file backup',
                      onTap: () => _startRestore(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Version info
                Center(
                  child: Text(
                    'NyatetPesse • v1.0.0',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
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
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).colorScheme.surface,
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
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
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).hintColor),
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

// ── Gemini API Key Bottom Sheet ────────────────────────────────────────────────
class _GeminiApiKeySheet extends StatefulWidget {
  final dynamic geminiService;
  const _GeminiApiKeySheet({required this.geminiService});

  @override
  State<_GeminiApiKeySheet> createState() => _GeminiApiKeySheetState();
}

class _GeminiApiKeySheetState extends State<_GeminiApiKeySheet> {
  final _controller = TextEditingController();
  bool _hasKey = false;
  bool _isLoading = true;
  bool _obscure = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentKey();
  }

  Future<void> _loadCurrentKey() async {
    final hasKey = await widget.geminiService.hasApiKey();
    final key = await widget.geminiService.getApiKey();
    if (mounted) {
      setState(() {
        _hasKey = hasKey;
        _isLoading = false;
        if (key != null) _controller.text = key;
      });
    }
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    setState(() => _isSaving = true);
    await widget.geminiService.saveApiKey(key);
    if (mounted) {
      setState(() {
        _hasKey = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ API Key berhasil disimpan! Gemini AI aktif.'),
          backgroundColor: AppTheme.income,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    await widget.geminiService.deleteApiKey();
    if (mounted) {
      setState(() {
        _hasKey = false;
        _controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key dihapus. Kembali ke mode regex.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFEC4899), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gemini AI Parser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                  Text('Google AI Studio API Key', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasKey ? AppTheme.income.withValues(alpha: 0.1) : Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _hasKey ? 'Aktif' : 'Tidak Aktif',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: _hasKey ? AppTheme.income : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'API Key disimpan terenkripsi di perangkat. Dapatkan key gratis di aistudio.google.com',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Input field
          if (_isLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'AIza...',
                labelText: 'Gemini API Key',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              if (_hasKey)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.expense,
                      side: const BorderSide(color: AppTheme.expense),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Hapus Key'),
                  ),
                ),
              if (_hasKey) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan & Aktifkan', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

