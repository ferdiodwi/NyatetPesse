import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/settings_provider.dart';
import 'package:nyatet_pesse/notification/services/notification_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final TextEditingController _keyController = TextEditingController();

  int _currentPage = 0;
  bool _notifGranted = false;
  bool _checkingPermission = true;
  bool _savingKey = false;
  bool _keySaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.isPermissionGranted();
    if (mounted) {
      setState(() {
        _notifGranted = granted;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _finish() async {
    final key = _keyController.text.trim();
    if (!_keySaved && key.isNotEmpty) {
      setState(() => _savingKey = true);
      await ref.read(geminiServiceProvider).saveApiKey(key);
    }
    await ref.read(onboardingControllerProvider.notifier).complete();
    ref.invalidate(onboardingCompleteProvider);
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == 2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Lewati ───────────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Lewati',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  const _IntroPage(),
                  _PermissionPage(
                    granted: _notifGranted,
                    checking: _checkingPermission,
                    onOpenSettings: () async {
                      // Android 13+: izin notifikasi runtime untuk aksi cepat.
                      await Permission.notification.request();
                      await NotificationService.openSettings();
                    },
                  ),
                  _AiPage(
                    controller: _keyController,
                    saving: _savingKey,
                    saved: _keySaved,
                    onSave: () async {
                      final key = _keyController.text.trim();
                      if (key.isEmpty) return;
                      setState(() => _savingKey = true);
                      await ref.read(geminiServiceProvider).saveApiKey(key);
                      if (mounted) {
                        setState(() {
                          _savingKey = false;
                          _keySaved = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Dots ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary : Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            // ── Button ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 24, 36, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    isLast ? 'MULAI' : 'LANJUT',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Intro ──────────────────────────────────────────────────────────────
class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Illustration(
            centerIcon: Icons.account_balance_wallet_rounded,
            chips: [
              (Icons.account_balance_rounded, 'Bank'),
              (Icons.smartphone_rounded, 'E-Wallet'),
              (Icons.payments_rounded, 'Cash'),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'Semua keuangan di satu tempat',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(height: 1.2),
          ),
          const SizedBox(height: 14),
          Text(
            'Pantau saldo bank, e-wallet, dan uang tunai Anda dalam satu dashboard terpusat dan rapi.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Permission ─────────────────────────────────────────────────────────
class _PermissionPage extends StatelessWidget {
  final bool granted;
  final bool checking;
  final Future<void> Function() onOpenSettings;

  const _PermissionPage({
    required this.granted,
    required this.checking,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Illustration(
            centerIcon: Icons.notifications_active_rounded,
            chips: [
              (Icons.account_balance_rounded, 'BCA'),
              (Icons.smartphone_rounded, 'DANA'),
              (Icons.shopping_bag_rounded, 'GoPay'),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'Catat otomatis dari notifikasi',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(height: 1.2),
          ),
          const SizedBox(height: 14),
          Text(
            'Izinkan NyatetPesse membaca notifikasi bank & e-wallet Anda. Pemrosesan terjadi di perangkat — transaksi masuk otomatis ke Inbox untuk Anda konfirmasi.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          _buildPermissionButton(),
        ],
      ),
    );
  }

  Widget _buildPermissionButton() {
    if (checking) {
      return const SizedBox(
        height: 46,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (granted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.income.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.income.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.income, size: 20),
            SizedBox(width: 8),
            Text(
              'Izin aktif — siap mencatat otomatis!',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF166534),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onOpenSettings,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: AppTheme.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: const Icon(Icons.settings_rounded, size: 18),
      label: const Text(
        'Aktifkan Izin Notifikasi',
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Page 3: AI opsional ────────────────────────────────────────────────────────
class _AiPage extends StatelessWidget {
  final TextEditingController controller;
  final bool saving;
  final bool saved;
  final Future<void> Function() onSave;

  const _AiPage({
    required this.controller,
    required this.saving,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const _Illustration(
            centerIcon: Icons.auto_awesome_rounded,
            chips: [
              (Icons.bolt_rounded, 'Cepat'),
              (Icons.lock_rounded, 'Privasi'),
              (Icons.offline_bolt_rounded, 'Offline'),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            'AI opsional, privasi tetap aman',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(height: 1.2),
          ),
          const SizedBox(height: 14),
          Text(
            'Aplikasi sudah bekerja offline dengan rule engine lokal. Ingin akurasi lebih tinggi? Isi API key Gemini pribadi Anda — tanpa itu, tidak ada data yang keluar dari perangkat.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (!saved)
            Column(
              children: [
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'AIza...',
                    labelText: 'Gemini API Key (opsional)',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gratis dari aistudio.google.com — disimpan terenkripsi di perangkat.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: saving ? null : onSave,
                  child: Text(
                    saving ? 'Menyimpan...' : 'Simpan key ini',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.income.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.income.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.income, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI Parser aktif!',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
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

// ── Ilustrasi lingkaran ala mockup ─────────────────────────────────────────────
class _Illustration extends StatelessWidget {
  final IconData centerIcon;
  final List<(IconData, String)> chips;

  const _Illustration({required this.centerIcon, required this.chips});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lingkaran luar
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.06),
                  AppTheme.primary.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
            ),
          ),
          // Orbit ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
          ),
          // Icon pusat
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Icon(centerIcon, size: 38, color: AppTheme.primary),
          ),
          // Chips posisi
          _PositionedChip(
            chip: chips[0],
            alignment: const Alignment(-0.85, -0.75),
          ),
          _PositionedChip(
            chip: chips[1],
            alignment: const Alignment(0.9, -0.45),
          ),
          _PositionedChip(
            chip: chips[2],
            alignment: const Alignment(0.35, 0.95),
          ),
        ],
      ),
    );
  }
}

class _PositionedChip extends StatelessWidget {
  final (IconData, String) chip;
  final Alignment alignment;

  const _PositionedChip({required this.chip, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(chip.$1, size: 12, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              chip.$2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
