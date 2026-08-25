import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:nyatet_pesse/data/database/app_database.dart';

/// Hasil operasi backup/restore.
class BackupResult {
  final bool success;
  final String? filePath;
  final String? error;

  const BackupResult.success(this.filePath)
      : success = true,
        error = null;
  const BackupResult.failure(this.error)
      : success = false,
        filePath = null;
}

/// Backup & restore database terenkripsi.
///
/// File database sudah terenkripsi di rest (sqlite3mc) dengan passphrase
/// perangkat di secure storage. Strategi backup:
///  1. Checkpoint WAL lalu salin file DB ke temp.
///  2. `PRAGMA rekey` salinan tersebut ke password backup pilihan pengguna.
///  3. File hasil dibagikan via share sheet (bisa disimpan ke Drive/lokal).
///
/// Restore membalik prosesnya: verifikasi password → rekey ke passphrase
/// perangkat → ganti file DB → aplikasi dimulai ulang.
class BackupService {
  final FlutterSecureStorage _storage;

  BackupService(this._storage);

  Future<String> get _devicePassphrase async =>
      (await _storage.read(key: kDbPassphraseStorageKey))!;

  Future<File> get _databaseFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}$kDatabaseFileName');
  }

  static String _escape(String s) => s.replaceAll("'", "''");

  // ── Backup ──────────────────────────────────────────────────────────────────
  /// Membuat file backup terenkripsi dengan [backupPassword].
  /// Mengembalikan path file yang siap dibagikan.
  Future<BackupResult> createBackupFile(String backupPassword) async {
    try {
      final dbFile = await _databaseFile;
      if (!await dbFile.exists()) {
        return const BackupResult.failure('Database belum dibuat.');
      }

      // 1. Checkpoint WAL agar seluruh data ada di file utama.
      final deviceKey = await _devicePassphrase;
      final main = sqlite3.open(dbFile.path);
      try {
        main.execute("PRAGMA key = '${_escape(deviceKey)}'");
        main.execute('PRAGMA wal_checkpoint(TRUNCATE);');
      } finally {
        main.close();
      }

      // 2. Salin ke file backup.
      final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      final tmp = File(
          '${(await getTemporaryDirectory()).path}/NyatetPesse-Backup-$stamp.sqlite');
      if (await tmp.exists()) await tmp.delete();
      await dbFile.copy(tmp.path);

      // 3. Rekey salinan ke password backup pengguna.
      final copy = sqlite3.open(tmp.path);
      try {
        copy.execute("PRAGMA key = '${_escape(deviceKey)}'");
        copy.select('SELECT count(*) FROM sqlite_master;');
        copy.execute("PRAGMA rekey = '${_escape(backupPassword)}'");
        // Verifikasi kunci baru benar-benar aktif.
        copy.select('SELECT count(*) FROM sqlite_master;');
      } finally {
        copy.close();
      }

      debugPrint('Backup created: ${tmp.path}');
      return BackupResult.success(tmp.path);
    } catch (e) {
      return BackupResult.failure(e.toString());
    }
  }

  // ── Restore ─────────────────────────────────────────────────────────────────
  /// Memulihkan database dari [backupFile] yang terenkripsi dengan
  /// [backupPassword].
  ///
  /// Memverifikasi password, rekey ke passphrase perangkat, lalu mengganti
  /// file database aktif (yang lama disimpan sebagai .bak). Pemanggil wajib
  /// menutup AppDatabase sebelum memanggil method ini dan me-restart
  /// aplikasi setelahnya.
  Future<BackupResult> restoreFrom(File backupFile, String backupPassword) async {
    try {
      if (!await backupFile.exists()) {
        return const BackupResult.failure('File backup tidak ditemukan.');
      }

      final deviceKey = await _devicePassphrase;

      // 1. Verifikasi password + rekey salinan ke passphrase perangkat.
      final tmp = File(
          '${(await getTemporaryDirectory()).path}/nyatetpesse-restore.sqlite');
      if (await tmp.exists()) await tmp.delete();
      await backupFile.copy(tmp.path);

      final restored = sqlite3.open(tmp.path);
      try {
        restored.execute("PRAGMA key = '${_escape(backupPassword)}'");
        // SELECT akan gagal (file is not a database) bila password salah.
        restored.select('SELECT count(*) FROM sqlite_master;');
      } catch (_) {
        restored.dispose();
        await tmp.delete();
        return const BackupResult.failure(
            'Password backup salah atau file rusak.');
      }
      restored.execute("PRAGMA rekey = '${_escape(deviceKey)}'");
      restored.select('SELECT count(*) FROM sqlite_master;');
      restored.close();

      // 2. Ganti file database aktif.
      final dbFile = await _databaseFile;

      final wal = File('${dbFile.path}-wal');
      final shm = File('${dbFile.path}-shm');
      if (await wal.exists()) await wal.delete();
      if (await shm.exists()) await shm.delete();

      if (await dbFile.exists()) {
        final bak = File('${dbFile.path}.pre-restore.bak');
        if (await bak.exists()) await bak.delete();
        await dbFile.rename(bak.path);
      }
      await tmp.rename(dbFile.path);

      debugPrint('Database restored from ${backupFile.path}');
      return const BackupResult.success(null);
    } catch (e) {
      return BackupResult.failure(e.toString());
    }
  }
}
