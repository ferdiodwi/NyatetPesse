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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat PIN Baru'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Masukkan 6 Digit PIN',
                    ),
                  ),
                  TextField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi PIN',
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Batal'),
                ),
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
            );
          }
        );
      },
    );
  }

  void _showRemovePinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus PIN?'),
          content: const Text('Fitur kunci aplikasi akan dinonaktifkan sepenuhnya (termasuk Biometrik).'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityControllerProvider);
    final controller = ref.watch(securityControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keamanan & Privasi'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Kunci Aplikasi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('PIN Aplikasi'),
            subtitle: Text(securityState.hasPinSet ? 'Aktif' : 'Belum Dibuat'),
            trailing: securityState.hasPinSet
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _showRemovePinDialog,
                  )
                : const Icon(Icons.chevron_right),
            onTap: securityState.hasPinSet ? null : _showSetPinDialog,
          ),
          if (securityState.hasPinSet && securityState.isBiometricSupported)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Gunakan Sidik Jari / Face ID'),
              subtitle: const Text('Buka aplikasi tanpa memasukkan PIN'),
              value: securityState.isBiometricEnabled,
              onChanged: (value) async {
                if (value) {
                  // Authenticate first before enabling
                  final success = await controller.authenticateWithBiometric();
                  if (success) {
                    controller.setBiometricEnabled(true);
                  } else if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Gagal verifikasi biometrik')),
                     );
                  }
                } else {
                  controller.setBiometricEnabled(false);
                }
              },
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Info: Saat kunci aplikasi aktif, Anda akan diminta memasukkan PIN setiap kali membuka aplikasi.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
