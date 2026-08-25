import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Accounts,
  Categories,
  Transactions,
  TransactionItems,
  InboxItems,
  TransactionImages,
  BudgetSettings,
  RecurringTransactions,
  NotificationSources,
  Reconciliations,
  CorrectionLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) : super(_openConnection(secureStorage));

  /// Untuk unit test — executor di-inject langsung (mis. NativeDatabase.memory).
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Seed default account
        await into(accounts).insert(
          AccountsCompanion.insert(
            name: 'Cash',
            type: 'CASH',
            currentBalance: const Value(0.0),
            createdAt: DateTime.now(),
          ),
        );
        
        // Seed default categories
        final defaultCategories = [
          CategoriesCompanion.insert(name: 'Makan & Minum', type: 'EXPENSE', icon: const Value('restaurant'), color: const Value('FFF44336'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Transportasi', type: 'EXPENSE', icon: const Value('directions_car'), color: const Value('FF2196F3'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Belanja', type: 'EXPENSE', icon: const Value('shopping_bag'), color: const Value('FFFF9800'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Gaji', type: 'INCOME', icon: const Value('payments'), color: const Value('FF4CAF50'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Transfer Keluar', type: 'TRANSFER', icon: const Value('arrow_upward'), color: const Value('FF9E9E9E'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Transfer Masuk', type: 'TRANSFER', icon: const Value('arrow_downward'), color: const Value('FF9E9E9E'), createdAt: DateTime.now()),
        ];
        
        for (var cat in defaultCategories) {
          await into(categories).insert(cat);
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Implement migrations here when schemaVersion increments
      },
    );
  }
}

/// Nama file database — dipakai juga oleh BackupService.
const String kDatabaseFileName = 'nyatetpesse_db.sqlite';

/// Key secure storage untuk passphrase database — dipakai juga oleh
/// BackupService saat rekey backup/restore.
const String kDbPassphraseStorageKey = 'db_passphrase';

String _escapeString(String source) => source.replaceAll("'", "''");

/// Mengambil passphrase database dari secure storage, atau membuat dan
/// menyimpannya jika belum ada (32 byte acak, di-encode base64Url).
Future<String> _getOrCreatePassphrase(FlutterSecureStorage storage) async {
  var passphrase = await storage.read(key: kDbPassphraseStorageKey);
  if (passphrase == null || passphrase.isEmpty) {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    passphrase = base64UrlEncode(bytes);
    await storage.write(key: kDbPassphraseStorageKey, value: passphrase);
  }
  return passphrase;
}

/// Memeriksa apakah file database masih plaintext (header SQLite standar).
Future<bool> _isPlaintextDatabase(File dbFile) async {
  final raf = await dbFile.open(mode: FileMode.read);
  try {
    final header = await raf.read(16);
    const plainHeader = <int>[
      0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
      0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
    ];
    return _bytesEqual(header, plainHeader);
  } finally {
    await raf.close();
  }
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Memigrasi database plaintext lama menjadi terenkripsi.
/// Pola resmi drift: VACUUM INTO salinan baru, lalu PRAGMA rekey.
Future<void> _migratePlaintextIfNeeded(File dbFile, String passphrase) async {
  if (!await dbFile.exists()) return;
  if (!await _isPlaintextDatabase(dbFile)) return;

  debugPrint('Migrating existing plaintext database to encrypted...');

  final tmp = File('${dbFile.path}.enc.tmp');
  if (await tmp.exists()) await tmp.delete();

  final plaintextDb = sqlite3.open(dbFile.path)
    ..execute("VACUUM INTO '${_escapeString(tmp.path)}';");
  plaintextDb.close();

  final encryptedDb = sqlite3.open(tmp.path)
    ..execute("PRAGMA rekey = '${_escapeString(passphrase)}';");
  encryptedDb.close();

  final backup = File('${dbFile.path}.plain.bak');
  if (await backup.exists()) await backup.delete();
  await dbFile.rename(backup.path);
  await tmp.rename(dbFile.path);

  debugPrint(
      'Migration complete. Plaintext copy kept as ${p.basename(backup.path)} — delete it manually after verifying the app.');
}

LazyDatabase _openConnection(FlutterSecureStorage secureStorage) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, kDatabaseFileName));
    final passphrase = await _getOrCreatePassphrase(secureStorage);

    await _migratePlaintextIfNeeded(file, passphrase);

    return NativeDatabase.createInBackground(
      file,
      isolateSetup: () async => _migratePlaintextIfNeeded(file, passphrase),
      setup: (rawDb) {
        // Gagal keras bila library enkripsi tidak tersedia — jangan pernah
        // diam-diam menyimpan data finansial sebagai plaintext.
        if (rawDb.select('PRAGMA cipher;').isEmpty) {
          throw StateError(
              'SQLite3MultipleCiphers is not available; refusing to open an unencrypted financial database.');
        }
        rawDb.execute("PRAGMA key = '${_escapeString(passphrase)}'");
        // Verifikasi kunci benar sebelum drift menyentuh database.
        rawDb.select('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}
