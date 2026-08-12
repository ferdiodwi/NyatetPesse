import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/screens/main_screen.dart';
import 'package:nyatet_pesse/features/security/presentation/screens/app_lock_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NyatetPesse',
      theme: AppTheme.lightTheme,
      home: const AppLockScreen(
        child: MainScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
