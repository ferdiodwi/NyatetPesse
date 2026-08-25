import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nyatet_pesse/notification/services/notification_service.dart';

/// True bila banner battery optimization perlu ditampilkan:
/// belum di-dismiss dan sistem masih mengoptimasi baterai app.
final batteryBannerProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('battery_banner_dismissed') ?? false) return false;
  return !(await NotificationService.isBatteryOptimizationIgnored());
});

class BatteryOptimizationBanner extends ConsumerWidget {
  const BatteryOptimizationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(batteryBannerProvider).valueOrNull ?? false;
    if (!show) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.battery_saver_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deteksi otomatis bisa terhambat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Kecualikan NyatetPesse dari hemat baterai agar notifikasi bank/e-wallet selalu terbaca.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.requestIgnoreBatteryOptimization();
              // Beri waktu sistem menerapkan, lalu cek ulang.
              await Future.delayed(const Duration(seconds: 2));
              ref.invalidate(batteryBannerProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Izinkan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('battery_banner_dismissed', true);
              ref.invalidate(batteryBannerProvider);
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 16, color: Theme.of(context).hintColor),
            ),
          ),
        ],
      ),
    );
  }
}
