import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('database encryption (sqlite3mc via build hooks)', () {
    test('bundled SQLite has cipher support', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      expect(db.select('PRAGMA cipher;'), isNotEmpty,
          reason: 'pubspec hooks must bundle SQLite3MultipleCiphers, '
              'otherwise the app would silently store financial data as plaintext.');
    });

    test('encrypted file database round-trip with key', () {
      final dir = Directory.systemTemp.createTempSync('nyatetpesse_db_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}${Platform.pathSeparator}enc.sqlite';

      // Write with a key.
      final db = sqlite3.open(path);
      db.execute("PRAGMA key = 'test-passphrase'");
      db.execute('CREATE TABLE t (v TEXT NOT NULL)');
      db.execute("INSERT INTO t VALUES ('rahasia')");
      db.close();

      // File on disk must not have the plaintext SQLite magic header.
      final header = File(path).readAsBytesSync().sublist(0, 16);
      expect(String.fromCharCodes(header), isNot(startsWith('SQLite format')));

      // Reopen with the correct key and read back.
      final reopened = sqlite3.open(path);
      reopened.execute("PRAGMA key = 'test-passphrase'");
      expect(reopened.select('SELECT v FROM t').first['v'], 'rahasia');
      reopened.dispose();
    });

    test('wrong key cannot read the encrypted file', () {
      final dir = Directory.systemTemp.createTempSync('nyatetpesse_db_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}${Platform.pathSeparator}enc.sqlite';

      final db = sqlite3.open(path);
      db.execute("PRAGMA key = 'correct-key'");
      db.execute('CREATE TABLE t (v TEXT NOT NULL)');
      db.close();

      final wrongKey = sqlite3.open(path);
      wrongKey.execute("PRAGMA key = 'wrong-key'");
      expect(
        () => wrongKey.select('SELECT count(*) FROM sqlite_master'),
        throwsA(anything),
      );
      wrongKey.dispose();
    });
  });
}
