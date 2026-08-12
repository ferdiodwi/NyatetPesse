import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Accounts,
  Categories,
  Transactions,
  TransactionItems,
  InboxItems,
  TransactionImages,
  BudgetSettings,
  RecurringTransactions,
  NotificationSources,
  Reconciliations,
  CorrectionLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Seed default account
        await into(accounts).insert(
          AccountsCompanion.insert(
            name: 'Cash',
            type: 'CASH',
            currentBalance: const Value(0.0),
            createdAt: DateTime.now(),
          ),
        );
        
        // Seed default categories
        final defaultCategories = [
          CategoriesCompanion.insert(name: 'Makan & Minum', type: 'EXPENSE', icon: const Value('restaurant'), color: const Value('FFF44336'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Transportasi', type: 'EXPENSE', icon: const Value('directions_car'), color: const Value('FF2196F3'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Belanja', type: 'EXPENSE', icon: const Value('shopping_bag'), color: const Value('FFFF9800'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Gaji', type: 'INCOME', icon: const Value('payments'), color: const Value('FF4CAF50'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Transfer Keluar', type: 'TRANSFER', icon: const Value('arrow_upward'), color: const Value('FF9E9E9E'), createdAt: DateTime.now()),
          CategoriesCompanion.insert(name: 'Transfer Masuk', type: 'TRANSFER', icon: const Value('arrow_downward'), color: const Value('FF9E9E9E'), createdAt: DateTime.now()),
        ];
        
        for (var cat in defaultCategories) {
          await into(categories).insert(cat);
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Implement migrations here when schemaVersion increments
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'nyatetpesse_db.sqlite'));

    // Workaround for some android devices
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase.createInBackground(file);
  });
}
