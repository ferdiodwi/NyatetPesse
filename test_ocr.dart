import 'package:nyatet_pesse/features/transactions/domain/parsers/ocr_parser.dart';

void main() {
  String sampleReceipt = """
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
  """;

  final result = OcrParser.parse(sampleReceipt);
  print("Merchant: " + (result.merchant ?? "null"));
  print("Amount: " + (result.amount?.toString() ?? "null"));
  print("Date: " + (result.date?.toString() ?? "null"));
  print("Type: " + result.type);
}
