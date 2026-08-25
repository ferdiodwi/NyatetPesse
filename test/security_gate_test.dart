import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyatet_pesse/features/security/presentation/providers/security_provider.dart';

class _FakeSecureStorage extends FlutterSecureStoragePlatform {
  final Map<String, String> values = {};

  @override
  Future<String?> read({required String key, Map<String, String>? options}) async =>
      values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    Map<String, String>? options,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({required String key, Map<String, String>? options}) async {
    values.remove(key);
  }

  @override
  Future<void> deleteAll({Map<String, String>? options}) async => values.clear();

  @override
  Future<Map<String, String>> readAll({Map<String, String>? options}) async =>
      Map.of(values);

  @override
  Future<bool> containsKey({
    required String key,
    Map<String, String>? options,
  }) async =>
      values.containsKey(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSecureStorage storage;

  setUp(() {
    storage = _FakeSecureStorage();
    FlutterSecureStoragePlatform.instance = storage;

    // Stub fingerprint check (method channel biometric).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.nyatet_pesse/biometric'),
      (call) async => call.method == 'isFingerprintAvailable' ? false : null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.nyatet_pesse/biometric'),
      null,
    );
  });

  /// Jalankan _init() sampai selesai (state isInitialized true).
  Future<SecurityController> initializedController() async {
    final controller = SecurityController(const FlutterSecureStorage());
    // Tunggu async _init selesai.
    for (var i = 0; i < 10; i++) {
      if (controller.state.isInitialized) break;
      await Future<void>.delayed(Duration.zero);
    }
    return controller;
  }

  group('SecurityController cold start (bug dashboard bocor sebelum cek sesi)', () {
    test('dengan PIN tersimpan → langsung locked saat init selesai', () async {
      storage.values['user_pin'] = '123456';

      final controller = await initializedController();

      // Kunci invariants: init tuntas DAN app langsung terkunci —
      // tidak ada jendela waktu di mana dashboard tampil tanpa sesi dicek.
      expect(controller.state.isInitialized, isTrue);
      expect(controller.state.isAppLocked, isTrue);
      expect(controller.state.hasPinSet, isTrue);
      controller.dispose();
    });

    test('tanpa PIN → unlocked setelah init', () async {
      final controller = await initializedController();

      expect(controller.state.isInitialized, isTrue);
      expect(controller.state.isAppLocked, isFalse);
      expect(controller.state.hasPinSet, isFalse);
      controller.dispose();
    });

    test('PIN benar → terbuka; PIN salah → tetap terkunci', () async {
      storage.values['user_pin'] = '123456';
      final controller = await initializedController();

      final wrong = await controller.verifyPin('000000');
      expect(wrong, isFalse);
      expect(controller.state.isAppLocked, isTrue);

      final right = await controller.verifyPin('123456');
      expect(right, isTrue);
      expect(controller.state.isAppLocked, isFalse);
      controller.dispose();
    });

    test('lockApp() mengunci kembali setelah unlock', () async {
      storage.values['user_pin'] = '123456';
      final controller = await initializedController();

      await controller.verifyPin('123456');
      expect(controller.state.isAppLocked, isFalse);

      controller.lockApp();
      expect(controller.state.isAppLocked, isTrue);
      controller.dispose();
    });
  });
}
