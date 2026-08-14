import 'package:nyatet_pesse/features/inbox/domain/services/transaction_parser.dart';

void main() {
  final parser = TransactionParser();
  
  String packageName = "com.b1.dbseabank";
  String title = "Transfer Masuk";
  String text = "Kamu menerima transfer saldo senilai Rp10.000 dari MUHAMMAD ZIDANE JULIAN SAPUTRA.";
  
  final result = parser.parseNotification(packageName, title, text);
  
  if (result != null) {
    print("Parsed!");
    print("Amount: ${result.amount}");
    print("Type: ${result.type}");
    print("Merchant: ${result.merchant}");
  } else {
    print("Failed to parse.");
  }
}
