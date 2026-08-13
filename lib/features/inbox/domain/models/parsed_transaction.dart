class ParsedTransaction {
  final double amount;
  final String? merchant;
  final String type; // 'income', 'expense', 'transfer', 'top_up'
  final String? category;
  final double confidenceScore; // 0.0 to 1.0

  ParsedTransaction({
    required this.amount,
    this.merchant,
    required this.type,
    this.category,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'merchant': merchant,
      'type': type,
      'category': category,
      'confidenceScore': confidenceScore,
    };
  }

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      amount: (json['amount'] as num).toDouble(),
      merchant: json['merchant'] as String?,
      type: json['type'] as String,
      category: json['category'] as String?,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
    );
  }
}
