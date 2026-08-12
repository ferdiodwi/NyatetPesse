import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionType { expense, income, transfer }

final transactionTypeProvider = StateProvider<TransactionType>((ref) => TransactionType.expense);
