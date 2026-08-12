import 'package:drift/drift.dart';

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('Account')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'bank', 'ewallet', 'cash', 'other'
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'income', 'expense'
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('TransactionEntity')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'income', 'expense', 'transfer', 'top_up'
  RealColumn get amount => real()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  @ReferenceName('transferDestination')
  IntColumn get destinationAccountId => integer().nullable().references(Accounts, #id)(); // for transfer
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get merchant => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get transactionTime => text().nullable()(); // 'HH:mm'
  TextColumn get source => text()(); // 'manual', 'notification', 'ocr_receipt', 'ocr_screenshot', 'import'
  TextColumn get sourceApp => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('confirmed'))(); // 'pending', 'confirmed', 'rejected'
  RealColumn get confidenceScore => real().nullable()();
  TextColumn get referenceId => text().nullable()();
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(true))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  IntColumn get recurringId => integer().nullable()(); // references RecurringTransactions later
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

@DataClassName('TransactionItem')
class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get price => real()();
  RealColumn get subtotal => real()();
}

@DataClassName('InboxItem')
class InboxItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawText => text()();
  TextColumn get source => text()(); // 'notification', 'ocr_receipt', 'ocr_screenshot'
  TextColumn get sourceApp => text().nullable()();
  TextColumn get extractedData => text().nullable()(); // JSON
  RealColumn get confidenceScore => real().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'confirmed', 'rejected', 'duplicate'
  IntColumn get duplicateOf => integer().nullable().references(Transactions, #id)();
  DateTimeColumn get detectedAt => dateTime()();
  DateTimeColumn get processedAt => dateTime().nullable()();
}

@DataClassName('TransactionImage')
class TransactionImages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  TextColumn get filePath => text()();
  TextColumn get imageType => text()(); // 'receipt', 'screenshot'
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('BudgetSetting')
class BudgetSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get period => text().withDefault(const Constant('monthly'))();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

@DataClassName('RecurringTransaction')
class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'income', 'expense'
  RealColumn get amount => real()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get interval => text()(); // 'daily', 'weekly', 'monthly'
  DateTimeColumn get nextDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('NotificationSource')
class NotificationSources extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get appName => text()();
  TextColumn get packageName => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isPreset => boolean().withDefault(const Constant(false))();
  DateTimeColumn get addedAt => dateTime()();
}

@DataClassName('Reconciliation')
class Reconciliations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  RealColumn get recordedBalance => real()();
  RealColumn get actualBalance => real()();
  RealColumn get difference => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get reconciledAt => dateTime()();
}

@DataClassName('CorrectionLog')
class CorrectionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionIdOrInputText => text()();
  TextColumn get fieldCorrected => text()();
  TextColumn get predictedLabel => text().nullable()();
  TextColumn get correctedLabel => text().nullable()();
  RealColumn get originalConfidence => real().nullable()();
  TextColumn get modelVersion => text().nullable()();
  DateTimeColumn get correctedAt => dateTime()();
}
