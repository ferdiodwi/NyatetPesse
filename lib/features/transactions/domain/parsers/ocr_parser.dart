class OcrParser {
  static OcrResult parse(String rawText) {
    double? amount;
    String? merchant;
    DateTime? date;
    String type = 'EXPENSE'; // Default for receipt

    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Look for Date (common formats: DD/MM/YY, DD-MM-YYYY, DD MMM YYYY)
      if (date == null) {
        final extractedDate = _extractDateFromLine(line);
        if (extractedDate != null) {
          date = extractedDate;
        }
      }

      // Look for amount (usually near 'total', 'jumlah', 'tagihan', or 'rp')
      if (amount == null) {
        final lineNoSpace = line.replaceAll(RegExp(r'\s+'), '').replaceAll('0', 'o');
        if (lineNoSpace.contains('total') || lineNoSpace.contains('jumlah') || lineNoSpace.contains('tagihan') || lineNoSpace.contains('rp')) {
          // Exclude subtotal or tax if possible
          if (!lineNoSpace.contains('sub') && !lineNoSpace.contains('pajak') && !lineNoSpace.contains('tax')) {
            final possibleAmount = _extractAmountFromLine(line);
            if (possibleAmount != null && possibleAmount > 0) {
              amount = possibleAmount;
            } else if (i + 1 < lines.length) {
              // Sometimes the amount is isolated on the next line
              final nextLineAmount = _extractAmountFromLine(lines[i + 1]);
              if (nextLineAmount != null && nextLineAmount > 0) {
                amount = nextLineAmount;
              }
            }
          }
        }
      }
      
      // Look for transfer success (income or expense)
      if (line.contains('berhasil') && line.contains('transfer')) {
         type = 'TRANSFER';
      }
      if (line.contains('terima uang') || line.contains('top up') || line.contains('berhasil top up')) {
         type = 'INCOME';
      }
    }
    
    // Guessing merchant from the first few lines
    for (int i = 0; i < lines.length && i < 4; i++) {
      final possibleMerchant = lines[i];
      final lower = possibleMerchant.toLowerCase();
      
      // Ignore common receipt headers or locations
      if (lower.contains('jl.') || lower.contains('jalan') || lower.contains('telp') || 
          lower.contains('npwp') || lower.contains('struk') || lower.contains('invoice') ||
          lower.contains('kasir') || lower.contains('tanggal') || RegExp(r'\d{4,}').hasMatch(possibleMerchant)) {
        continue;
      }
      
      if (possibleMerchant.length > 3 && possibleMerchant.length < 30) {
        merchant = possibleMerchant;
        break; // Found the most likely merchant
      }
    }

    // Fallback if no amount found but there's a big number in the receipt
    if (amount == null) {
      for (final line in lines.reversed) {
        final possibleAmount = _extractAmountFromLine(line);
        if (possibleAmount != null && possibleAmount > 1000) {
          amount = possibleAmount;
          break;
        }
      }
    }

    return OcrResult(
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      rawText: rawText,
    );
  }

  static double? _extractAmountFromLine(String line) {
    // Regex to find numbers that look like currency (e.g. 50.000 or 50,000 or 1.234.567)
    // Matches 1 to 3 digits followed by optional dots/commas and 3 digits
    // Also handles spaces that OCR might accidentally insert like R p . 5 0 . 0 0 0
    final cleanLine = line.replaceAll(RegExp(r'\s+'), '');
    
    final regex = RegExp(r'(?:rp)?(?:idr)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)\b', caseSensitive: false);
    
    for (final match in regex.allMatches(cleanLine)) {
      final amountStr = match.group(1);
      if (amountStr != null) {
        String cleanStr = amountStr.replaceAll('.', '');
        cleanStr = cleanStr.replaceAll(',', '.'); // if decimals exist
        final val = double.tryParse(cleanStr);
        // Exclude tiny numbers like quantity or item numbers
        if (val != null && val > 100) {
          return val;
        }
      }
    }
    return null;
  }

  static DateTime? _extractDateFromLine(String line) {
    // Matches DD/MM/YY, DD/MM/YYYY, DD-MM-YYYY
    final regex = RegExp(r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b');
    final match = regex.firstMatch(line);
    
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        
        if (year < 100) {
          year += 2000;
        }
        
        if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
          return DateTime(year, month, day);
        }
      } catch (e) {
        // ignore
      }
    }
    return null;
  }
}

class OcrResult {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final String type;
  final String rawText;

  OcrResult({
    this.amount,
    this.merchant,
    this.date,
    required this.type,
    required this.rawText,
  });
}
