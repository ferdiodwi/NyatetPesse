import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/notification/services/notification_service.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> with WidgetsBindingObserver {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        _hasPermission = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
      ),
      body: ListView(
        children: [
          _buildPermissionBanner(context),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'E-Wallet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
            ),
          ),
          SwitchListTile(
            title: const Text('OVO'),
            subtitle: const Text('ovo.id'),
            value: settings.isOvoEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_ovo', val),
          ),
          SwitchListTile(
            title: const Text('GoPay / Gojek'),
            subtitle: const Text('com.gojek.app / com.gopay.app'),
            value: settings.isGopayEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_gopay', val),
          ),
          SwitchListTile(
            title: const Text('DANA'),
            subtitle: const Text('id.dana'),
            value: settings.isDanaEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_dana', val),
          ),
          SwitchListTile(
            title: const Text('ShopeePay'),
            subtitle: const Text('com.shopee.id / com.shopeepay.id'),
            value: settings.isShopeePayEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_shopeepay', val),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'M-Banking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: const Text('BRImo (BRI)'),
            subtitle: const Text('id.co.bri.brimo'),
            value: settings.isBrimoEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_brimo', val),
          ),
          SwitchListTile(
            title: const Text('Livin\' by Mandiri'),
            subtitle: const Text('id.co.bankmandiri.livin'),
            value: settings.isMandiriEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_mandiri', val),
          ),
          SwitchListTile(
            title: const Text('BCA Mobile / myBCA'),
            subtitle: const Text('com.bca / com.bca.mybca'),
            value: settings.isBcaEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_bca', val),
          ),
          SwitchListTile(
            title: const Text('BNI / wondr by BNI'),
            subtitle: const Text('id.co.bni.mobilebanking'),
            value: settings.isBniEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_bni', val),
          ),
          SwitchListTile(
            title: const Text('SeaBank'),
            subtitle: const Text('com.bke.seabank'),
            value: settings.isSeaBankEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_seabank', val),
          ),
          SwitchListTile(
            title: const Text('Krom Bank'),
            subtitle: const Text('id.krom.bank'),
            value: settings.isKromEnabled,
            onChanged: (val) => notifier.toggleSetting('notif_krom', val),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasPermission 
            ? Colors.green.withValues(alpha: 0.1) 
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasPermission 
              ? Colors.green 
              : Theme.of(context).colorScheme.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasPermission ? Icons.check_circle : Icons.warning_amber_rounded,
                color: _hasPermission ? Colors.green : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasPermission ? 'Izin Akses Notifikasi Diberikan' : 'Izin Akses Notifikasi Diperlukan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _hasPermission ? Colors.green.shade800 : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _hasPermission
                ? 'Aplikasi sudah bisa membaca notifikasi dari bank dan e-wallet Anda.'
                : 'Agar aplikasi dapat mendeteksi transaksi otomatis, berikan izin Notification Access di Pengaturan HP Anda.',
            style: TextStyle(
              color: _hasPermission ? Colors.green.shade800 : Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          if (!_hasPermission) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                NotificationService.openSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Buka Pengaturan'),
            ),
          ]
        ],
      ),
    );
  }
}
