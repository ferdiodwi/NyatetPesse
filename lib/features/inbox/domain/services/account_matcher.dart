import 'package:drift/drift.dart' show Value;
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/account_repository.dart';

/// Hasil pencarian/pembuatan akun otomatis dari sumber notifikasi.
class AccountMatchResult {
  final int accountId;
  final bool created;
  final String? createdName;

  const AccountMatchResult({
    required this.accountId,
    this.created = false,
    this.createdName,
  });
}

/// Mencocokkan sumber notifikasi (packageName) dengan akun yang ada.
/// Dipakai oleh kartu inbox DAN auto-save dari aksi notifikasi Android.
class AccountMatcher {
  AccountMatcher._();

  /// Konfigurasi keyword per sumber app.
  static (List<String>, String?) _configFor(String sourceLower) {
    if (sourceLower.contains('seabank') || sourceLower.contains('bankbke')) {
      return (['seabank', 'sea bank', 'bke'], 'SeaBank');
    } else if (sourceLower.contains('dana')) {
      return (['dana'], 'DANA');
    } else if (sourceLower.contains('ovo')) {
      return (['ovo'], 'OVO');
    } else if (sourceLower.contains('gojek')) {
      return (['gopay', 'go-pay', 'gojek'], 'GoPay');
    } else if (sourceLower.contains('shopee')) {
      return (['shopeepay', 'shopee pay', 'spay'], 'ShopeePay');
    } else if (sourceLower.contains('bca')) {
      return (['bca'], 'BCA');
    } else if (sourceLower.contains('mandiri')) {
      return (['mandiri', 'livin'], 'Mandiri');
    } else if (sourceLower.contains('bni')) {
      return (['bni'], 'BNI');
    } else if (sourceLower.contains('bri')) {
      return (['bri', 'brimo'], 'BRI');
    } else if (sourceLower.contains('krom')) {
      return (['krom'], 'Krom');
    }
    return (<String>[], null);
  }

  /// Mencocokkan [sourceApp] dengan daftar [accounts] berdasarkan nama.
  /// Mengembalikan null bila tidak ada yang cocok.
  static int? matchAccount(List<Account> accounts, String? sourceApp) {
    if (sourceApp == null) return null;
    final (keywords, _) = _configFor(sourceApp.toLowerCase());
    for (final keyword in keywords) {
      for (final account in accounts) {
        if (account.name.toLowerCase().contains(keyword)) return account.id;
      }
    }
    return null;
  }

  /// Cocokkan akun; bila tidak ada dan sumber dikenali, buat akun baru
  /// secara otomatis. Mengembalikan [AccountMatchResult] dengan
  /// [AccountMatchResult.created] == true bila akun baru dibuat.
  /// Melempar [StateError] bila tidak ada akun dan sumber tidak dikenali.
  static Future<AccountMatchResult> findOrCreate(
    AccountRepository repo,
    List<Account> accounts,
    String? sourceApp,
  ) async {
    final matched = matchAccount(accounts, sourceApp);
    if (matched != null) return AccountMatchResult(accountId: matched);

    if (sourceApp != null) {
      final (_, defaultName) = _configFor(sourceApp.toLowerCase());
      if (defaultName != null) {
        final newId = await repo.addAccount(
          AccountsCompanion.insert(
            name: defaultName,
            type: 'E-WALLET',
            currentBalance: const Value(0.0),
            createdAt: DateTime.now(),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return AccountMatchResult(
          accountId: newId,
          created: true,
          createdName: defaultName,
        );
      }
    }

    if (accounts.isNotEmpty) {
      return AccountMatchResult(accountId: accounts.first.id);
    }
    throw StateError('Tidak ada akun tersedia');
  }
}
