import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

class SecurityState {
  final bool isAppLocked; // Whether the app is currently showing the lock screen
  final bool hasPinSet;   // Whether the user has set a PIN
  final bool isBiometricEnabled; // Whether biometric is allowed by user
  final bool isBiometricSupported; // Whether device supports biometric

  SecurityState({
    this.isAppLocked = false,
    this.hasPinSet = false,
    this.isBiometricEnabled = false,
    this.isBiometricSupported = false,
  });

  SecurityState copyWith({
    bool? isAppLocked,
    bool? hasPinSet,
    bool? isBiometricEnabled,
    bool? isBiometricSupported,
  }) {
    return SecurityState(
      isAppLocked: isAppLocked ?? this.isAppLocked,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricSupported: isBiometricSupported ?? this.isBiometricSupported,
    );
  }
}

class SecurityController extends StateNotifier<SecurityState> {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  SecurityController(this._storage, this._auth) : super(SecurityState()) {
    _init();
  }

  Future<void> _init() async {
    final pin = await _storage.read(key: 'user_pin');
    final biometricStr = await _storage.read(key: 'use_biometric');
    
    bool isSupported = false;
    try {
      isSupported = await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {}

    final hasPin = pin != null && pin.isNotEmpty;

    state = state.copyWith(
      hasPinSet: hasPin,
      isAppLocked: hasPin, // If there's a PIN, lock the app on startup
      isBiometricEnabled: biometricStr == 'true',
      isBiometricSupported: isSupported,
    );
  }

  Future<bool> setPin(String newPin) async {
    await _storage.write(key: 'user_pin', value: newPin);
    state = state.copyWith(hasPinSet: true);
    return true;
  }

  Future<bool> removePin() async {
    await _storage.delete(key: 'user_pin');
    await _storage.delete(key: 'use_biometric');
    state = state.copyWith(hasPinSet: false, isBiometricEnabled: false, isAppLocked: false);
    return true;
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: 'use_biometric', value: enabled.toString());
    state = state.copyWith(isBiometricEnabled: enabled);
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: 'user_pin');
    if (savedPin == pin) {
      state = state.copyWith(isAppLocked: false);
      return true;
    }
    return false;
  }

  Future<bool> authenticateWithBiometric() async {
    if (!state.isBiometricSupported) return false;

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari atau wajah Anda untuk membuka NyatetPesse',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        state = state.copyWith(isAppLocked: false);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }
  
  void lockApp() {
    if (state.hasPinSet) {
      state = state.copyWith(isAppLocked: true);
    }
  }
}

final securityControllerProvider = StateNotifierProvider<SecurityController, SecurityState>((ref) {
  return SecurityController(
    ref.watch(secureStorageProvider),
    ref.watch(localAuthProvider),
  );
});
