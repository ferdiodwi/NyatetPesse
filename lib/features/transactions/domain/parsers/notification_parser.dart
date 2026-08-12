import 'package:nyatet_pesse/core/services/notification_service.dart';

class ParsedTransaction {
  final String source; // e.g. BCA, DANA
  final double amount;
  final String? type; // INCOME, EXPENSE, TRANSFER
  final String? rawText;
  
  ParsedTransaction({
    required this.source,
    required this.amount,
    this.type,
    this.rawText,
  });
}

class NotificationParser {
  
  static ParsedTransaction? parse(NotificationData data) {
    final text = '${data.title} ${data.text}'.toLowerCase();
    
    // 1. DANA Parser
    if (data.packageName == 'id.dana') {
      // Example DANA: "Berhasil top up Rp 50.000" or "Kirim uang Rp 10.000 berhasil"
      final amount = _extractAmount(text);
      if (amount != null) {
        String type = 'EXPENSE';
        if (text.contains('top up') || text.contains('terima uang') || text.contains('berhasil top up')) {
          type = 'INCOME';
        } else if (text.contains('kirim uang') || text.contains('pembayaran')) {
          type = 'EXPENSE';
        }
        
        return ParsedTransaction(
          source: 'DANA',
          amount: amount,
          type: type,
          rawText: data.text,
        );
      }
    }
    
    // 2. BCA Mobile Parser
    if (data.packageName == 'com.bca') {
      // Example BCA: "M-Transfer Berhasil Rp 100,000"
      final amount = _extractAmount(text);
      if (amount != null) {
         // Usually BCA notif for transfer is Expense
         return ParsedTransaction(
           source: 'BCA',
           amount: amount,
           type: 'EXPENSE',
           rawText: data.text,
         );
      }
    }
    
    // Add GoPay, OVO, Mandiri later based on actual notification text format
    
    return null;
  }
  
  static double? _extractAmount(String text) {
    // Basic regex to find "rp" followed by numbers
    final regex = RegExp(r'rp\s*(\d{1,3}(?:\.\d{3})*(?:,\d+)?)');
    final match = regex.firstMatch(text);
    if (match != null) {
      final amountStr = match.group(1);
      if (amountStr != null) {
        // Remove dots
        final cleanStr = amountStr.replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(cleanStr);
      }
    }
    return null;
  }
}
