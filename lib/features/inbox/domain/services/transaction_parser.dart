import 'package:nyatet_pesse/features/inbox/domain/models/parsed_transaction.dart';

class TransactionParser {
  /// Parses the raw notification text into a ParsedTransaction using Rule-Based Regex.
  /// Returns null if the notification is not a valid transaction (e.g. promos, OTPs).
  ParsedTransaction? parseNotification(String packageName, String title, String text) {
    final lowerTitle = title.toLowerCase();
    final lowerText = text.toLowerCase();
    final combinedText = '$lowerTitle $lowerText';

    // Whitelist allowed financial/e-wallet apps to prevent reading system notifications
    final allowedPackages = ['id.dana', 'ovo.id', 'com.gojek.app', 'com.shopee.id', 'com.bca', 'com.bankmandiri'];
    bool isAllowed = false;
    for (final pkg in allowedPackages) {
      if (packageName.toLowerCase().contains(pkg)) {
        isAllowed = true;
        break;
      }
    }
    
    // Fallback: If it's a test broadcast with no package or unknown package, we can ignore it 
    // BUT since we just sent mock notifications using package names like "id.dana" and "ovo.id", it's fine.
    if (!isAllowed) {
      return null;
    }

    // Filter out non-transactional notifications
    if (combinedText.contains('otp') ||
        combinedText.contains('kode verifikasi') ||
        combinedText.contains('promo') ||
        combinedText.contains('cashback') && !combinedText.contains('berhasil') ||
        combinedText.contains('jangan berikan')) {
      return null;
    }

    double? amount = _extractAmount(combinedText);
    if (amount == null || amount <= 0) {
      return null; // Not a transaction if there's no amount
    }

    String type = _determineType(packageName, combinedText);
    String? merchant = _extractMerchant(packageName, title, text);

    // Rule-based confidence
    double confidence = 0.6; // Base confidence
    if (merchant != null && merchant.isNotEmpty) confidence += 0.2;
    if (type != 'expense') confidence += 0.1; // Incomes are usually easier to guess correctly

    // Cap at 0.9 (leave 1.0 for manual or high certainty ML)
    confidence = confidence > 0.9 ? 0.9 : confidence;

    return ParsedTransaction(
      amount: amount,
      merchant: merchant,
      type: type,
      confidenceScore: confidence,
    );
  }

  double? _extractAmount(String text) {
    // Matches Rp10.000, Rp 10.000, Rp. 10.000, 10.000,00
    // Removed the global flag since Dart regex doesn't use it the same way inline
    final regex = RegExp(r'(?:rp\s*\.?\s*)?(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)', caseSensitive: false);
    final match = regex.firstMatch(text);
    
    if (match != null && match.groupCount >= 1) {
      String rawAmount = match.group(1)!;
      // Remove dots
      rawAmount = rawAmount.replaceAll('.', '');
      // Replace comma with dot for decimal
      rawAmount = rawAmount.replaceAll(',', '.');
      return double.tryParse(rawAmount);
    }
    return null;
  }

  String _determineType(String packageName, String text) {
    if (text.contains('berhasil top up') || text.contains('top up berhasil') || text.contains('isi saldo')) {
      return 'top_up';
    }
    if (text.contains('berhasil transfer') || text.contains('kirim uang') || text.contains('pembayaran') || text.contains('bayar')) {
      return 'expense';
    }
    if (text.contains('menerima') || text.contains('masuk') || text.contains('terima dana') || text.contains('uang masuk')) {
      return 'income';
    }
    return 'expense'; // Default fallback
  }

  String? _extractMerchant(String packageName, String title, String text) {
    // Simple rule-based extraction for known patterns
    if (packageName.contains('id.dana')) {
      // DANA often says "Pembayaran RpX ke [Merchant] berhasil"
      final regex = RegExp(r'ke\s+(.*?)\s+berhasil', caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) return match.group(1)?.trim();
    }
    
    if (packageName.contains('ovo')) {
      // OVO often says "Pembayaran di [Merchant] sebesar..."
      final regex = RegExp(r'di\s+(.*?)\s+sebesar', caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) return match.group(1)?.trim();
    }

    if (packageName.contains('gojek')) {
      // GoPay often has "Gopay kamu terpotong RpX untuk [Merchant]"
      final regex = RegExp(r'untuk\s+(.*?)\.', caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) return match.group(1)?.trim();
    }

    return null; // Fallback, let user fill it in or ML model later
  }
}
