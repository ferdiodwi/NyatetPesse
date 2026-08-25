import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userNameProvider = StateNotifierProvider<UserNameNotifier, String>((ref) {
  return UserNameNotifier();
});

class UserNameNotifier extends StateNotifier<String> {
  UserNameNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('user_name') ?? '';
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove('user_name');
    } else {
      await prefs.setString('user_name', trimmed);
    }
    state = trimmed;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeModeSetting>((ref) {
  return ThemeModeNotifier();
});

enum ThemeModeSetting { system, light, dark }

class ThemeModeNotifier extends StateNotifier<ThemeModeSetting> {
  ThemeModeNotifier() : super(ThemeModeSetting.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    state = ThemeModeSetting.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeModeSetting.system,
    );
  }

  Future<void> setMode(ThemeModeSetting mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    state = mode;
  }
}

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
});

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, bool>((ref) {
  return OnboardingController();
});

class OnboardingController extends StateNotifier<bool> {
  OnboardingController() : super(false);

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    state = true;
  }
}

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsState {
  // E-Wallet
  final bool isOvoEnabled;
  final bool isGopayEnabled;
  final bool isDanaEnabled;
  final bool isShopeePayEnabled;

  // MBanking
  final bool isBrimoEnabled;
  final bool isMandiriEnabled;
  final bool isBcaEnabled;
  final bool isBniEnabled;
  final bool isSeaBankEnabled;
  final bool isKromEnabled;

  NotificationSettingsState({
    this.isOvoEnabled = true,
    this.isGopayEnabled = true,
    this.isDanaEnabled = true,
    this.isShopeePayEnabled = true,
    this.isBrimoEnabled = true,
    this.isMandiriEnabled = true,
    this.isBcaEnabled = true,
    this.isBniEnabled = true,
    this.isSeaBankEnabled = true,
    this.isKromEnabled = true,
  });

  NotificationSettingsState copyWith({
    bool? isOvoEnabled,
    bool? isGopayEnabled,
    bool? isDanaEnabled,
    bool? isShopeePayEnabled,
    bool? isBrimoEnabled,
    bool? isMandiriEnabled,
    bool? isBcaEnabled,
    bool? isBniEnabled,
    bool? isSeaBankEnabled,
    bool? isKromEnabled,
  }) {
    return NotificationSettingsState(
      isOvoEnabled: isOvoEnabled ?? this.isOvoEnabled,
      isGopayEnabled: isGopayEnabled ?? this.isGopayEnabled,
      isDanaEnabled: isDanaEnabled ?? this.isDanaEnabled,
      isShopeePayEnabled: isShopeePayEnabled ?? this.isShopeePayEnabled,
      isBrimoEnabled: isBrimoEnabled ?? this.isBrimoEnabled,
      isMandiriEnabled: isMandiriEnabled ?? this.isMandiriEnabled,
      isBcaEnabled: isBcaEnabled ?? this.isBcaEnabled,
      isBniEnabled: isBniEnabled ?? this.isBniEnabled,
      isSeaBankEnabled: isSeaBankEnabled ?? this.isSeaBankEnabled,
      isKromEnabled: isKromEnabled ?? this.isKromEnabled,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier() : super(NotificationSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      isOvoEnabled: prefs.getBool('notif_ovo') ?? true,
      isGopayEnabled: prefs.getBool('notif_gopay') ?? true,
      isDanaEnabled: prefs.getBool('notif_dana') ?? true,
      isShopeePayEnabled: prefs.getBool('notif_shopeepay') ?? true,
      isBrimoEnabled: prefs.getBool('notif_brimo') ?? true,
      isMandiriEnabled: prefs.getBool('notif_mandiri') ?? true,
      isBcaEnabled: prefs.getBool('notif_bca') ?? true,
      isBniEnabled: prefs.getBool('notif_bni') ?? true,
      isSeaBankEnabled: prefs.getBool('notif_seabank') ?? true,
      isKromEnabled: prefs.getBool('notif_krom') ?? true,
    );
  }

  Future<void> toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    switch (key) {
      case 'notif_ovo': state = state.copyWith(isOvoEnabled: value); break;
      case 'notif_gopay': state = state.copyWith(isGopayEnabled: value); break;
      case 'notif_dana': state = state.copyWith(isDanaEnabled: value); break;
      case 'notif_shopeepay': state = state.copyWith(isShopeePayEnabled: value); break;
      case 'notif_brimo': state = state.copyWith(isBrimoEnabled: value); break;
      case 'notif_mandiri': state = state.copyWith(isMandiriEnabled: value); break;
      case 'notif_bca': state = state.copyWith(isBcaEnabled: value); break;
      case 'notif_bni': state = state.copyWith(isBniEnabled: value); break;
      case 'notif_seabank': state = state.copyWith(isSeaBankEnabled: value); break;
      case 'notif_krom': state = state.copyWith(isKromEnabled: value); break;
    }
  }
}
