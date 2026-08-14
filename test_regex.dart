void main() {
  String line = "jumlah : 5, rp 10.000";
  final cleanLine = line.replaceAll(RegExp(r'\s+'), '');
  final regex = RegExp(r'(?:rp)?(?:idr)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)\b', caseSensitive: false);
  
  for (final match in regex.allMatches(cleanLine)) {
    final amountStr = match.group(1);
    if (amountStr != null) {
      String cleanStr = amountStr.replaceAll('.', '');
      cleanStr = cleanStr.replaceAll(',', '.');
      final val = double.tryParse(cleanStr);
      if (val != null && val > 100) {
        print("Found: $val");
        return;
      }
    }
  }
}
