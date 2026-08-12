import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionFilter { all, income, expense, transfer }

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter.all);
