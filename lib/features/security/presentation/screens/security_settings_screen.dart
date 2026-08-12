import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/features/security/presentation/providers/security_provider.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _showSetPinDialog() {
    setState(() {
      _errorMessage = null;
      _pinController.clear();
      _confirmPinController.clear();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buat PIN Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Masukkan 6 Digit PIN'),
              ),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Konfirmasi PIN'),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (_pinController.text.length != 6) {
                  setDialogState(() => _errorMessage = 'PIN harus 6 digit');
                  return;
                }
                if (_pinController.text != _confirmPinController.text) {
                  setDialogState(() => _errorMessage = 'Konfirmasi PIN tidak cocok');
                  return;
                }
                await ref.read(securityControllerProvider.notifier).setPin(_pinController.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemovePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus PIN?'),
        content: const Text('Kunci aplikasi dan sidik jari akan dinonaktifkan sepenuhnya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(securityControllerProvider.notifier).removePin();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(securityControllerProvider);
    final controller = ref.read(securityControllerProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan & Privasi')),
      body: ListView(
        children: [
          // ── PIN ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Kunci Aplikasi',
                style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('PIN Aplikasi'),
            subtitle: Text(s.hasPinSet ? 'Aktif' : 'Belum dibuat — ketuk untuk membuat PIN'),
            trailing: s.hasPinSet
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: _showSetPinDialog, child: const Text('Ganti')),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Hapus PIN',
                        onPressed: _showRemovePinDialog,
                      ),
                    ],
                  )
                : const Icon(Icons.chevron_right),
            onTap: s.hasPinSet ? null : _showSetPinDialog,
          ),

          // ── FINGERPRINT ──────────────────────────────────────
          if (s.hasPinSet) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Biometrik',
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            if (!s.isBiometricSupported)
              const ListTile(
                leading: Icon(Icons.info_outline, color: Colors.grey),
                title: Text('Tidak Didukung'),
                subtitle: Text('Perangkat tidak memiliki sensor sidik jari.'),
              )
            else
              SwitchListTile(
                secondary: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: s.isBiometricEnabled
                        ? primary.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    color: s.isBiometricEnabled ? primary : Colors.grey,
                    size: 26,
                  ),
                ),
                title: const Text('Sidik Jari', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  s.isBiometricEnabled
                      ? 'Aktif — gunakan sidik jari untuk membuka kunci'
                      : 'Nonaktif',
                  style: const TextStyle(fontSize: 12),
                ),
                value: s.isBiometricEnabled,
                onChanged: (value) async {
                  if (value) {
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await controller.authenticateWithBiometric();
                    if (!success) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Verifikasi sidik jari gagal.')),
                      );
                    }
                    if (success) await controller.setBiometricEnabled(true);
                  } else {
                    await controller.setBiometricEnabled(false);
                  }
                },
              ),
          ],

          // ── INFO ─────────────────────────────────────────────
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              s.hasPinSet
                  ? s.isBiometricEnabled
                      ? 'Saat aplikasi dikunci, Anda bisa menggunakan sidik jari atau memasukkan PIN.'
                      : 'Saat aplikasi dikunci, Anda perlu memasukkan PIN.'
                  : 'Buat PIN terlebih dahulu untuk mengaktifkan kunci aplikasi dan sidik jari.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
