import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';

class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

  Future<void> exportTransactionsToCsv() async {
    // Fetch all transactions with joined account and category
    final query = _db.select(_db.transactions).join([
      innerJoin(_db.accounts, _db.accounts.id.equalsExp(_db.transactions.accountId)),
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
    ])..orderBy([OrderingTerm.desc(_db.transactions.transactionDate)]);

    final rows = await query.get();

    // Prepare CSV header
    List<List<dynamic>> csvData = [
      ['ID', 'Tanggal', 'Tipe', 'Nominal', 'Kategori', 'Akun', 'Merchant', 'Catatan', 'Sumber']
    ];

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Add rows
    for (final row in rows) {
      final t = row.readTable(_db.transactions);
      final acc = row.readTable(_db.accounts);
      final cat = row.readTableOrNull(_db.categories);

      csvData.add([
        t.id,
        dateFormat.format(t.transactionDate),
        t.type,
        t.amount,
        cat?.name ?? '-',
        acc.name,
        t.merchant ?? '-',
        t.description ?? '-',
        t.source,
      ]);
    }

    // Convert to CSV
    String csvString = const ListToCsvConverter().convert(csvData);

    // Get temp directory to save the file
    final tempDir = await getTemporaryDirectory();
    final fileDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/NyatetPesse_Export_$fileDate.csv');

    // Write file
    await file.writeAsString(csvString);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export Riwayat Transaksi NyatetPesse',
    );
  }
}
