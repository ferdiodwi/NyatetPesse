import 'package:nyatet_pesse/features/inbox/domain/models/parsed_transaction.dart';

class TransactionParser {
  /// Parses the raw notification text into a ParsedTransaction using Rule-Based Regex.
  /// Returns null if the notification is not a valid transaction (e.g. promos, OTPs).
  ParsedTransaction? parseNotification(String packageName, String title, String text) {
    final lowerTitle = title.toLowerCase();
    final lowerText = text.toLowerCase();
    final combinedText = '$lowerTitle $lowerText';

    // Whitelist allowed financial/e-wallet apps
    final allowedPackages = [
      'id.dana',
      'ovo.id',
      'com.gojek.app',
      'com.shopee.id',
      'com.bca',
      'com.bankmandiri',
      'seabank',
      'bankbke',
    ];
    bool isAllowed = false;
    for (final pkg in allowedPackages) {
      if (packageName.toLowerCase().contains(pkg)) {
        isAllowed = true;
        break;
      }
    }
    if (!isAllowed) return null;

    // Filter out non-transactional notifications
    final isOtp = combinedText.contains('otp') ||
        combinedText.contains('kode verifikasi') ||
        combinedText.contains('kode keamanan') ||
        combinedText.contains('jangan berikan') ||
        combinedText.contains('kode rahasia');

    final isPromo = (combinedText.contains('promo') ||
            combinedText.contains('cashback') ||
            combinedText.contains('diskon') ||
            combinedText.contains('voucher') ||
            combinedText.contains('flash sale') ||
            combinedText.contains('hadiah')) &&
        !combinedText.contains('berhasil') &&
        !combinedText.contains('diterima') &&
        !combinedText.contains('pembayaran');

    if (isOtp || isPromo) return null;

    // ── Amount ──────────────────────────────────────────────────────────────────
    // Amount MUST be explicitly prefixed with "rp" to avoid false positives like
    // version numbers, dates, order IDs, etc.
    double? amount = _extractAmount(combinedText);
    if (amount == null || amount <= 0) return null;

    // ── Type & Merchant ─────────────────────────────────────────────────────────
    String type = _determineType(packageName, combinedText);
    String? merchant = _extractMerchant(packageName, title, text, combinedText);

    // ── Confidence ──────────────────────────────────────────────────────────────
    double confidence = 0.6;
    if (merchant != null && merchant.isNotEmpty) confidence += 0.2;
    if (type == 'income') confidence += 0.1;
    if (confidence > 0.9) confidence = 0.9;

    return ParsedTransaction(
      amount: amount,
      merchant: merchant,
      type: type,
      confidenceScore: confidence,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Amount Extraction
  // HARUS diawali "rp" agar tidak menangkap angka acak seperti nomor pesanan / versi.
  // ─────────────────────────────────────────────────────────────────────────────
  double? _extractAmount(String text) {
    // Matches: Rp10.000 / Rp 10.000 / Rp. 10.000 / Rp10.000,00 / Rp 1.000.000
    final regex = RegExp(
      r'rp\.?\s*([\d]{1,3}(?:[.,]\d{3})*(?:[,.]\d{1,2})?)',
      caseSensitive: false,
    );

    double? best;

    for (final match in regex.allMatches(text)) {
      String raw = match.group(1)!;

      // Handle Indonesian format: 1.000.000 (dots as thousands) or 1.000,50
      // vs decimal format: 1,000.50
      double? parsed;

      if (raw.contains(',') && raw.contains('.')) {
        // e.g. "1.000,50" — dot = thousands separator, comma = decimal
        raw = raw.replaceAll('.', '').replaceAll(',', '.');
        parsed = double.tryParse(raw);
      } else if (raw.contains('.') && !raw.contains(',')) {
        // Could be "10.000" (thousands) or "10.5" (decimal)
        final parts = raw.split('.');
        if (parts.last.length == 3) {
          // Likely thousands separator (10.000, 1.000.000)
          raw = raw.replaceAll('.', '');
          parsed = double.tryParse(raw);
        } else {
          // Likely decimal (10.50)
          parsed = double.tryParse(raw);
        }
      } else if (raw.contains(',') && !raw.contains('.')) {
        // e.g. "10,000" — could be thousands (US) or decimal (ID)
        final parts = raw.split(',');
        if (parts.last.length == 3) {
          raw = raw.replaceAll(',', '');
          parsed = double.tryParse(raw);
        } else {
          raw = raw.replaceAll(',', '.');
          parsed = double.tryParse(raw);
        }
      } else {
        parsed = double.tryParse(raw);
      }

      // Take the LARGEST amount found — usually the transaction value
      if (parsed != null && parsed > (best ?? 0)) {
        best = parsed;
      }
    }

    return best;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Type Determination
  // ─────────────────────────────────────────────────────────────────────────────
  String _determineType(String packageName, String text) {
    // Income keywords
    if (text.contains('menerima') ||
        text.contains('uang masuk') ||
        text.contains('transfer masuk') ||
        text.contains('terima dana') ||
        text.contains('kamu menerima') ||
        text.contains('dana masuk') ||
        text.contains('top up berhasil') ||
        text.contains('berhasil top up') ||
        text.contains('isi saldo berhasil')) {
      return 'income';
    }

    // Expense / payment keywords
    if (text.contains('pembayaran') ||
        text.contains('bayar') ||
        text.contains('melakukan transfer') ||
        text.contains('berhasil transfer') ||
        text.contains('kirim uang') ||
        text.contains('dikurangi') ||
        text.contains('terpotong') ||
        text.contains('debit')) {
      return 'expense';
    }

    return 'expense'; // Default
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Merchant Extraction — per app
  // ─────────────────────────────────────────────────────────────────────────────
  String? _extractMerchant(String packageName, String title, String text, String combinedText) {
    // ── DANA ────────────────────────────────────────────────────────────────────
    if (packageName.contains('id.dana')) {
      // "Pembayaran Rp10.000 ke Tokopedia berhasil"
      var m = RegExp(r'ke\s+(.+?)\s+berhasil', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
      // "Kamu membayar [Merchant] Rp..."
      m = RegExp(r'membayar\s+(.+?)\s+rp', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
    }

    // ── OVO ─────────────────────────────────────────────────────────────────────
    if (packageName.contains('ovo')) {
      // "Pembayaran di Indomaret sebesar Rp..."
      var m = RegExp(r'di\s+(.+?)\s+sebesar', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
      // "Pembayaran OVO Cash ke Alfamart"
      m = RegExp(r'(?:cash|points?)\s+ke\s+(.+?)(?:\s+(?:sebesar|senilai|rp)|$)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
    }

    // ── GoPay / Gojek ────────────────────────────────────────────────────────────
    if (packageName.contains('gojek')) {
      // "GoPay kamu terpotong Rp15.000 untuk Indomaret."
      var m = RegExp(r'untuk\s+(.+?)(?:\.|$)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
      // "Kamu membayar ke [Merchant]"
      m = RegExp(r'ke\s+(.+?)(?:\s+(?:berhasil|rp)|$)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
    }

    // ── ShopeePay ───────────────────────────────────────────────────────────────
    if (packageName.contains('shopee')) {
      // "Pembayaran ShopeePay ke [Merchant] sebesar Rp..."
      var m = RegExp(r'(?:ke|kepada|di)\s+(.+?)\s+(?:sebesar|senilai|rp|berhasil)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
      // "Kamu membayar Rp... di [Merchant]"
      m = RegExp(r'di\s+(.+?)(?:\s+(?:berhasil|dengan|telah)|$)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
      // "Transfer ShopeePay ke [Name] berhasil"
      m = RegExp(r'(?:transfer|kirim)\s+(?:shopeepay\s+)?ke\s+(.+?)(?:\s+(?:berhasil|sebesar)|$)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
    }

    // ── BCA ─────────────────────────────────────────────────────────────────────
    if (packageName.contains('bca')) {
      var m = RegExp(r'(?:ke|kepada|toko)\s+(.+?)(?:\s+(?:berhasil|rp|sejumlah)|$)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
    }

    // ── Mandiri ──────────────────────────────────────────────────────────────────
    if (packageName.contains('mandiri')) {
      var m = RegExp(r'(?:ke|kepada)\s+(.+?)(?:\s+(?:berhasil|rp|sejumlah)|$)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
    }

    // ── SeaBank ──────────────────────────────────────────────────────────────────
    if (packageName.contains('seabank') || packageName.contains('bankbke')) {
      // Expense: "transfer senilai RpX kepada [Name] pada..."
      var m = RegExp(r'kepada\s+(.+?)\s+pada', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
      // Income: "menerima transfer saldo senilai RpX dari [Name]."
      m = RegExp(r'dari\s+([A-Z][A-Z\s]+?)(?:\.|$)', caseSensitive: false).firstMatch(text);
      if (m != null) return m.group(1)?.trim();
    }

    return null;
  }
}
