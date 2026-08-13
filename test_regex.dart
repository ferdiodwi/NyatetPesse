void main() {
  final text = "Pembayaran Rp 150.000 ke MCDONALDS berhasil";
  final regex = RegExp(r'(?:rp\s*\.?\s*)?(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)', caseSensitive: false);
  final match = regex.firstMatch(text);
  
  if (match != null && match.groupCount >= 1) {
    String rawAmount = match.group(1)!;
    print("Match: $rawAmount");
  } else {
    print("No match");
  }
}
