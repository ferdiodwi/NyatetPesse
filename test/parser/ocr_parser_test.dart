import 'package:flutter_test/flutter_test.dart';
import 'package:nyatet_pesse/features/transactions/domain/parsers/ocr_parser.dart';

void main() {
  group('OcrParser.parse', () {
    const indomaretReceipt = '''
INDOMARET JEND. SUDIRMAN
JL. JEND. SUDIRMAN NO. 123
NPWP: 01.234.567.8-901.000
12-08-2026 14:30

Milo UHT 200ml          5.000
Roti Tawar              12.000
Plastik Besar           500
--------------------------------
TOTAL                  Rp 17.500
TUNAI                  20.000
KEMBALI                2.500

Terima Kasih
Selamat Belanja Kembali
''';

    test('extracts total amount (not cash tendered) from receipt', () {
      final result = OcrParser.parse(indomaretReceipt);

      expect(result.amount, 17500);
    });

    test('extracts merchant from receipt header', () {
      final result = OcrParser.parse(indomaretReceipt);

      expect(result.merchant, 'INDOMARET JEND. SUDIRMAN');
    });

    test('extracts date in DD-MM-YYYY format', () {
      final result = OcrParser.parse(indomaretReceipt);

      expect(result.date, DateTime(2026, 8, 12));
    });

    test('defaults receipt type to expense', () {
      final result = OcrParser.parse(indomaretReceipt);

      expect(result.type, 'EXPENSE');
    });

    test('detects top up as income', () {
      final result = OcrParser.parse('''
SALDO KIOS
12-08-2026
Top up Rp 100.000 berhasil
''');

      expect(result.type, 'INCOME');
    });

    test('falls back to largest number when no total line exists', () {
      final result = OcrParser.parse('''
KOPI SENJA
13-08-2026
Americano   18.000
Croissant   22.000
''');

      // Fallback scans from the bottom and takes the first amount > 1000.
      expect(result.amount, 22000);
    });
  });
}
