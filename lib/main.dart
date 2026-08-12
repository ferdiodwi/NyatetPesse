import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/core/theme/app_theme.dart';
import 'package:nyatet_pesse/features/dashboard/presentation/screens/main_screen.dart';
import 'package:nyatet_pesse/features/security/presentation/screens/app_lock_screen.dart';

void main() {
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
