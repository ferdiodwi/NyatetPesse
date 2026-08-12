import 'package:flutter/services.dart';

/// Service untuk autentikasi sidik jari menggunakan BiometricPrompt native Android.
/// Menggunakan BIOMETRIC_STRONG sehingga HANYA sidik jari yang muncul — tanpa tab Wajah.
class FingerprintService {
  static const _channel = MethodChannel('com.example.nyatet_pesse/biometric');

  /// Cek apakah sidik jari tersedia dan terdaftar di perangkat
  static Future<bool> isFingerprintAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isFingerprintAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Tampilkan dialog sidik jari.
  /// Mengembalikan `true` jika berhasil, `false` jika dibatalkan / gagal.
  static Future<bool> authenticate({
    String title = 'Sidik Jari NyatetPesse',
    String subtitle = 'Pindai sidik jari.',
    String cancelText = 'Batalkan',
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('authenticateFingerprint', {
        'title': title,
        'subtitle': subtitle,
        'cancel': cancelText,
      });
      return result == 'success';
    } on PlatformException catch (_) {
      return false;
    }
  }
}
