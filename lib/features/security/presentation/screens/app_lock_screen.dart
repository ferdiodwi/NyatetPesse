import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/security/presentation/providers/security_provider.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockScreen({super.key, required this.child});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  final List<String> _pinDigits = [];
  bool _hasError = false;
  bool _isBiometricLoading = false;
  bool _userDismissedBiometric = false;
  DateTime? _pausedAt;

  static const int _pinLength = 6;
  static const _primary = Color(0xFF000666);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(securityControllerProvider);
      if (s.isBiometricEnabled && s.isBiometricSupported) {
        _tryBiometric();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Catat waktu kapan aplikasi masuk ke background
      if (_pausedAt == null) {
        _pausedAt = DateTime.now();
      }
      _userDismissedBiometric = false;
    } else if (state == AppLifecycleState.resumed) {
      // Saat kembali, cek selisih waktu
      if (_pausedAt != null) {
        final diff = DateTime.now().difference(_pausedAt!);
        if (diff.inMinutes >= 1) {
          // Jika sudah 1 menit atau lebih, kunci aplikasi
          ref.read(securityControllerProvider.notifier).lockApp();
        }
        // Reset waktu paused
        _pausedAt = null;
      }

      final s = ref.read(securityControllerProvider);
      if (s.isAppLocked && s.isBiometricEnabled && s.isBiometricSupported && !_userDismissedBiometric) {
        _tryBiometric();
      }
    }
  }

  Future<void> _tryBiometric() async {
    if (_isBiometricLoading || _userDismissedBiometric) return;
    setState(() => _isBiometricLoading = true);
    final success = await ref.read(securityControllerProvider.notifier).authenticateWithBiometric();
    if (mounted) {
      setState(() => _isBiometricLoading = false);
      if (!success) _userDismissedBiometric = true;
    }
  }

  // Immediate — no async delay on visual update
  void _onDigit(String d) {
    if (_pinDigits.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _hasError = false;
      _pinDigits.add(d);
    });

    if (_pinDigits.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_pinDigits.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _hasError = false;
      _pinDigits.removeLast();
    });
  }

  Future<void> _verifyPin() async {
    final pin = _pinDigits.join();
    final success = await ref.read(securityControllerProvider.notifier).verifyPin(pin);
    if (!success && mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _pinDigits.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(securityControllerProvider);
    if (!s.isAppLocked) return widget.child;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Spacer di atas logo agar letaknya agak ke tengah
            const SizedBox(height: 120),

            // ── Logo / App Icon ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/icon_baru.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'NyatetPesse',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),

            // Jarak yang lebih dekat antara logo dan ucapan selamat datang
            const SizedBox(height: 32),

            // ── Greeting ─────────────────────────────────────────
            const Text(
              'Selamat Datang Kembali, Ferdio',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),

            const SizedBox(height: 48),

            // ── PIN dots ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _pinDigits.length;
                return Container(
                  // Ubah margin ini agar jarak antar titik PIN lebih lebar
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? Colors.red
                        : filled
                            ? _primary
                            : Colors.transparent,
                    border: Border.all(
                      color: _hasError ? Colors.red : const Color(0xFFAAAAAA),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // ── Hint text ────────────────────────────────────────
            Text(
              _hasError ? 'PIN salah, coba lagi' : 'Masukkan PIN kamu',
              style: TextStyle(
                fontSize: 13,
                color: _hasError ? Colors.red : const Color(0xFF888888),
              ),
            ),

            const Spacer(),

            // ── Numpad ───────────────────────────────────────────
            _buildNumpad(s),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(SecurityState s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _numRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _numRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _numRow(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Fingerprint button (kiri)
              if (s.isBiometricEnabled && s.isBiometricSupported)
                _actionButton(
                  child: _isBiometricLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                        )
                      : const Icon(Icons.fingerprint, size: 30, color: _primary),
                  onTap: () {
                    _userDismissedBiometric = false;
                    _tryBiometric();
                  },
                  transparent: true,
                )
              else
                const SizedBox(width: 88, height: 72),

              _numButton('0'),

              // Backspace (kanan)
              _actionButton(
                child: const Icon(Icons.backspace_rounded, size: 22, color: Color(0xFF444444)),
                onTap: _onDelete,
                transparent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Row _numRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_numButton).toList(),
    );
  }

  Widget _numButton(String d) {
    return _PinButton(
      onTap: () => _onDigit(d),
      child: Text(
        d,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _actionButton({required Widget child, required VoidCallback onTap, bool transparent = false}) {
    return _PinButton(
      onTap: onTap,
      transparent: transparent,
      child: child,
    );
  }
}

/// Tombol numpad ringan tanpa delay — tidak ada AnimatedContainer atau setState ekstra
class _PinButton extends StatefulWidget {
  const _PinButton({required this.child, required this.onTap, this.transparent = false});
  final Widget child;
  final VoidCallback onTap;
  final bool transparent;

  @override
  State<_PinButton> createState() => _PinButtonState();
}

class _PinButtonState extends State<_PinButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        width: 88,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.transparent
              ? Colors.transparent
              : _pressed
                  ? const Color(0xFFDDDDDD)
                  : const Color(0xFFF0F0F0),
        ),
        child: widget.child,
      ),
    );
  }
}
