import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nyatet_pesse/core/services/fingerprint_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class SecurityState {
  final bool isAppLocked;
  final bool hasPinSet;
  final bool isBiometricEnabled;
  final bool isBiometricSupported; // apakah ada sidik jari di perangkat

  /// False sampai _init() selesai membaca secure storage.
  /// UI WAJIB menahan render child selama belum init agar dashboard
  /// tidak bocor tampil sebelum sesi dicek (cold start).
  final bool isInitialized;

  SecurityState({
    this.isAppLocked = false,
    this.hasPinSet = false,
    this.isBiometricEnabled = false,
    this.isBiometricSupported = false,
    this.isInitialized = false,
  });

  SecurityState copyWith({
    bool? isAppLocked,
    bool? hasPinSet,
    bool? isBiometricEnabled,
    bool? isBiometricSupported,
    bool? isInitialized,
  }) {
    return SecurityState(
      isAppLocked: isAppLocked ?? this.isAppLocked,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricSupported: isBiometricSupported ?? this.isBiometricSupported,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class SecurityController extends StateNotifier<SecurityState> {
  final FlutterSecureStorage _storage;

  SecurityController(this._storage) : super(SecurityState()) {
    _init();
  }

  Future<void> _init() async {
    final pin = await _storage.read(key: 'user_pin');
    final biometricStr = await _storage.read(key: 'use_biometric');
    final isSupported = await FingerprintService.isFingerprintAvailable();

    final hasPin = pin != null && pin.isNotEmpty;

    state = state.copyWith(
      hasPinSet: hasPin,
      isAppLocked: hasPin,
      isBiometricEnabled: biometricStr == 'true',
      isBiometricSupported: isSupported,
      isInitialized: true,
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
    state = state.copyWith(
      hasPinSet: false,
      isBiometricEnabled: false,
      isAppLocked: false,
    );
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

  /// Tampilkan prompt sidik jari — hanya sidik jari, tanpa tab Wajah.
  /// Jika user tekan "Batalkan", mengembalikan false → tetap di layar PIN.
  Future<bool> authenticateWithBiometric() async {
    if (!state.isBiometricSupported) return false;

    final success = await FingerprintService.authenticate(
      title: 'NyatetPesse',
      subtitle: 'Pindai sidik jari untuk membuka aplikasi',
      cancelText: 'Gunakan PIN',
    );

    if (success) {
      state = state.copyWith(isAppLocked: false);
    }
    return success;
  }

  void lockApp() {
    if (state.hasPinSet) {
      state = state.copyWith(isAppLocked: true);
    }
  }
}

final securityControllerProvider = StateNotifierProvider<SecurityController, SecurityState>((ref) {
  return SecurityController(ref.watch(secureStorageProvider));
});
