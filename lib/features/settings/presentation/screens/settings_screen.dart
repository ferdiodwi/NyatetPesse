import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/categories/presentation/screens/categories_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:nyatet_pesse/features/security/presentation/screens/security_settings_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/export_provider.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/recurring_transactions_screen.dart';
import 'package:nyatet_pesse/notification/services/notification_service.dart';

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
                        backgroundColor: Colors.white,
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
                color: AppTheme.borderColor,
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gemini AI Parser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text('Google AI Studio API Key', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasKey ? AppTheme.income.withValues(alpha: 0.1) : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _hasKey ? 'Aktif' : 'Tidak Aktif',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: _hasKey ? AppTheme.income : AppTheme.textSecondary,
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

