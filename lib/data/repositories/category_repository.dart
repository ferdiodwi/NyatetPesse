import 'package:nyatet_pesse/data/database/app_database.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Stream<List<Category>> watchAllCategories() {
    return _db.select(_db.categories).watch();
  }
  
  Stream<List<Category>> watchCategoriesByType(String type) {
    return (_db.select(_db.categories)..where((c) => c.type.equals(type))).watch();
  }

  Future<int> addCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insert(category);
  }

  Future<bool> updateCategory(Category category) {
    return _db.update(_db.categories).replace(category);
  }

  Future<int> deleteCategory(Category category) {
    return _db.delete(_db.categories).delete(category);
  }
}
