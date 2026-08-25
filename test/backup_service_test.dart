import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/features/settings/domain/services/backup_service.dart';
import 'package:sqlite3/sqlite3.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String docsPath;
  final String tempPath;
  _FakePathProvider(this.docsPath, this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

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
  Future<Map<String, String>> readAll({Map<String, String>? options}) async =>
      Map.of(values);

  @override
  Future<bool> containsKey({
    required String key,
    Map<String, String>? options,
  }) async =>
      values.containsKey(key);

  @override
  Future<void> deleteAll({Map<String, String>? options}) async {
    values.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docsDir;
  late Directory tempDir;
  late _FakeSecureStorage storage;
  late BackupService service;

  setUp(() async {
    docsDir = await Directory.systemTemp.createTemp('np_docs');
    tempDir = await Directory.systemTemp.createTemp('np_tmp');
    PathProviderPlatform.instance = _FakePathProvider(docsDir.path, tempDir.path);

    storage = _FakeSecureStorage();
    storage.values[kDbPassphraseStorageKey] = 'device-secret-key';
    FlutterSecureStoragePlatform.instance = storage;

    // BackupService memakai FlutterSecureStorage konkret yang di dalamnya
    // membaca FlutterSecureStoragePlatform.instance → fake di atas.
    service = BackupService(const FlutterSecureStorage());
  });

  tearDown(() async {
    await docsDir.delete(recursive: true);
    await tempDir.delete(recursive: true);
  });

  File dbFile() => File('${docsDir.path}${Platform.pathSeparator}$kDatabaseFileName');

  /// Buat database terenkripsi device-key berisi 1 tabel + 1 baris.
  void seedDeviceDatabase() {
    final db = sqlite3.open(dbFile().path);
    db.execute("PRAGMA key = 'device-secret-key'");
    db.execute('CREATE TABLE data (v TEXT NOT NULL)');
    db.execute("INSERT INTO data VALUES ('rahasia-penting')");
    db.close();
  }

  group('BackupService', () {
    test('createBackupFile menghasilkan file yang terbuka dengan password backup',
        () async {
      seedDeviceDatabase();

      final result = await service.createBackupFile('backup-pass-123');
      expect(result.success, isTrue, reason: result.error);
      expect(result.filePath, isNotNull);
      expect(File(result.filePath!).existsSync(), isTrue);

      // Terbuka dengan password backup.
      final copy = sqlite3.open(result.filePath!);
      copy.execute("PRAGMA key = 'backup-pass-123'");
      expect(copy.select('SELECT v FROM data').first['v'], 'rahasia-penting');
      copy.close();
    });

    test('file backup tidak bisa dibuka dengan kunci perangkat', () async {
      seedDeviceDatabase();

      final result = await service.createBackupFile('backup-pass-123');
      final copy = sqlite3.open(result.filePath!);
      copy.execute("PRAGMA key = 'device-secret-key'");
      expect(
        () => copy.select('SELECT count(*) FROM sqlite_master'),
        throwsA(anything),
      );
      copy.close();
    });

    test('restoreFrom mengganti DB aktif dan bisa dibuka kunci perangkat',
        () async {
      seedDeviceDatabase();

      final backup = await service.createBackupFile('backup-pass-123');

      // Ubah data aktif setelah backup — restore harus mengembalikannya.
      final mutate = sqlite3.open(dbFile().path);
      mutate.execute("PRAGMA key = 'device-secret-key'");
      mutate.execute("UPDATE data SET v = 'diubah-setelah-backup'");
      mutate.close();

      final result = await service.restoreFrom(File(backup.filePath!), 'backup-pass-123');
      expect(result.success, isTrue, reason: result.error);

      final reopened = sqlite3.open(dbFile().path);
      reopened.execute("PRAGMA key = 'device-secret-key'");
      expect(
        reopened.select('SELECT v FROM data').first['v'],
        'rahasia-penting',
      );
      reopened.close();

      // DB lama tersimpan sebagai .bak.
      expect(File('${dbFile().path}.pre-restore.bak').existsSync(), isTrue);
    });

    test('restoreFrom menolak password salah tanpa mengubah DB aktif', () async {
      seedDeviceDatabase();
      final backup = await service.createBackupFile('backup-pass-123');

      final result = await service.restoreFrom(File(backup.filePath!), 'password-salah');
      expect(result.success, isFalse);

      // DB aktif tidak berubah.
      final reopened = sqlite3.open(dbFile().path);
      reopened.execute("PRAGMA key = 'device-secret-key'");
      expect(
        reopened.select('SELECT v FROM data').first['v'],
        'rahasia-penting',
      );
      reopened.close();
    });
  });
}
