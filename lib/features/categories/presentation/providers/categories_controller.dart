import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';

class CategoriesController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CategoriesController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> saveCategory({
    required String name,
    required String type, // 'INCOME', 'EXPENSE'
    required String icon,
    required String color,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final repo = _ref.read(categoryRepositoryProvider);
      
      final companion = CategoriesCompanion.insert(
        name: name,
        type: type,
        icon: drift.Value(icon),
        color: drift.Value(color),
        isCustom: const drift.Value(true),
        isActive: const drift.Value(true),
        createdAt: DateTime.now(),
      );
      
      await repo.addCategory(companion);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final categoriesControllerProvider = StateNotifierProvider<CategoriesController, AsyncValue<void>>((ref) {
  return CategoriesController(ref);
});
