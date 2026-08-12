class OcrParser {
  static OcrResult parse(String rawText) {
    double? amount;
    String? merchant;
    String type = 'EXPENSE'; // Default for receipt

    final lines = rawText.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Look for amount (usually near 'total' or 'rp')
      if (line.contains('total') || line.contains('jumlah') || line.contains('rp') || line.contains('tagihan')) {
        // Try to find numbers in this line
        final possibleAmount = _extractAmountFromLine(line);
        if (possibleAmount != null && possibleAmount > 0) {
           amount = possibleAmount;
        } else if (i + 1 < lines.length) {
           // Sometimes the amount is on the next line
           final nextLineAmount = _extractAmountFromLine(lines[i + 1]);
           if (nextLineAmount != null && nextLineAmount > 0) {
             amount = nextLineAmount;
           }
        }
      }
      
      // Look for transfer success (income or expense)
      if (line.contains('berhasil') && line.contains('transfer')) {
         type = 'TRANSFER';
      }
      if (line.contains('terima uang') || line.contains('top up')) {
         type = 'INCOME';
      }
    }
    
    // Guessing merchant from the first few lines (usually the header)
    if (lines.isNotEmpty) {
      final firstLine = lines.first.trim();
      if (firstLine.isNotEmpty && firstLine.length > 3) {
        // Simple heuristic: if it doesn't contain numbers, it might be the store name
        if (!firstLine.contains(RegExp(r'\d'))) {
          merchant = firstLine;
        }
      }
    }

    return OcrResult(
      amount: amount,
      merchant: merchant,
      type: type,
      rawText: rawText,
    );
  }

  static double? _extractAmountFromLine(String line) {
    // Regex to find numbers that look like currency (e.g. 50.000 or 50,000 or 1.234.567)
    // Matches 1 to 3 digits followed by optional dots/commas and 3 digits
    final regex = RegExp(r'(?:rp\s*)?(?:idr\s*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)\b');
    final match = regex.firstMatch(line);
    
    if (match != null) {
      final amountStr = match.group(1);
      if (amountStr != null) {
        // Clean up string to be parsed as double
        // Assuming Indonesian format: dot is thousands separator, comma is decimal
        // This is a naive cleanup, works best if no decimals in Rupiah
        String cleanStr = amountStr.replaceAll('.', '');
        cleanStr = cleanStr.replaceAll(',', '.');
        return double.tryParse(cleanStr);
      }
    }
    return null;
  }
}

class OcrResult {
  final double? amount;
  final String? merchant;
  final String type;
  final String rawText;

  OcrResult({
    this.amount,
    this.merchant,
    required this.type,
    required this.rawText,
  });
}
