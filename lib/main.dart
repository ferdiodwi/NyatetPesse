import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/screens/main_screen.dart';
import 'package:nyatet_pesse/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:nyatet_pesse/features/security/presentation/screens/app_lock_screen.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/settings_provider.dart';
import 'package:nyatet_pesse/features/transactions/presentation/providers/recurring_controller.dart';
import 'package:nyatet_pesse/notification/services/notification_service.dart';

import 'package:intl/date_symbol_data_local.dart';

/// Nama task periodik WorkManager untuk memproses transaksi rutin.
const String kRecurringTask = 'nyatetpesse.recurringProcess';

/// Entry point background isolate — dipanggil WorkManager di luar UI.
/// Memproses transaksi rutin yang jatuh tempo meski aplikasi tidak dibuka.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final db = AppDatabase();
      try {
        await RecurringController(db).processDueTransactions();
      } finally {
        await db.close();
      }
      return true;
    } catch (e) {
      debugPrint('Recurring background task error: $e');
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Proses transaksi rutin di background (bertahan reboot).
  if (Platform.isAndroid) {
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        'nyatetpesse-recurring',
        kRecurringTask,
        frequency: const Duration(hours: 6),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: true,
        ),
      );
    } catch (e) {
      debugPrint('Workmanager init failed: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start listening to notifications from native side
    ref.watch(notificationServiceProvider).startListening();

    final onboardingDone = ref.watch(onboardingCompleteProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'NyatetPesse',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: switch (themeMode) {
        ThemeModeSetting.system => ThemeMode.system,
        ThemeModeSetting.light => ThemeMode.light,
        ThemeModeSetting.dark => ThemeMode.dark,
      },
      home: onboardingDone.when(
        loading: () => const _SplashScreen(),
        error: (_, __) => const AppLockScreen(child: MainScreen()),
        data: (done) => done
            ? const AppLockScreen(child: MainScreen())
            : const OnboardingScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/icon_baru.png', width: 88, height: 88),
            const SizedBox(height: 16),
            Text(
              'NyatetPesse',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
