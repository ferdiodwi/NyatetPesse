import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyatet_pesse/core/services/gemini_service.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/account_repository.dart';
import 'package:nyatet_pesse/data/repositories/inbox_repository.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/data/repositories/transaction_repository.dart';
import 'package:nyatet_pesse/features/inbox/domain/models/parsed_transaction.dart';
import 'package:nyatet_pesse/features/inbox/domain/services/account_matcher.dart';
import 'package:nyatet_pesse/features/inbox/domain/services/transaction_parser.dart';
import 'package:nyatet_pesse/features/security/presentation/providers/security_provider.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/settings_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(ref.watch(secureStorageProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(inboxRepositoryProvider),
    ref.watch(geminiServiceProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    () => ref.read(notificationSettingsProvider),
  );
});

/// Model data notifikasi yang diterima dari native (Kotlin) via EventChannel.
class NotificationData {
  final String packageName;
  final String title;
  final String text;
  final DateTime postTime;

  NotificationData({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
  });

  factory NotificationData.fromMap(Map<dynamic, dynamic> map) {
    return NotificationData(
      packageName: map['packageName'] ?? '',
      title: map['title'] ?? '',
      text: map['text'] ?? '',
      postTime: DateTime.fromMillisecondsSinceEpoch(map['postTime'] ?? 0),
    );
  }
}

class NotificationService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.nyatet_pesse/notification_method');
  static const EventChannel _eventChannel =
      EventChannel('com.example.nyatet_pesse/notification_event');

  final InboxRepository _inboxRepository;
  final GeminiService _gemini;
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final NotificationSettingsState Function() _readSettings;
  final TransactionParser _ruleParser = TransactionParser();
  bool _isListening = false;

  NotificationService(
    this._inboxRepository,
    this._gemini,
    this._transactionRepository,
    this._accountRepository,
    this._readSettings,
  );

  // ── Izin Notification Listener ──────────────────────────────────────────────
  static Future<bool> isPermissionGranted() async {
    try {
      final bool isEnabled =
          await _methodChannel.invokeMethod('isNotificationListenerEnabled');
      return isEnabled;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
    } on PlatformException {
      // Ignore
    }
  }

  // ── Battery Optimization (keandalan listener di MIUI/ColorOS dll) ──────────
  static Future<bool> isBatteryOptimizationIgnored() async {
    try {
      return await _methodChannel.invokeMethod('isBatteryOptimizationIgnored');
    } on PlatformException {
      return true; // Anggap aman bila channel tidak tersedia.
    }
  }

  static Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _methodChannel.invokeMethod('requestIgnoreBatteryOptimization');
    } on PlatformException {
      // Ignore
    }
  }

  // ── Notifikasi Inbox (aksi cepat Simpan/Abaikan) ────────────────────────────
  Future<void> showInboxNotification({
    required int inboxId,
    required String title,
    required String body,
  }) async {
    try {
      await _methodChannel.invokeMethod('showInboxNotification', {
        'id': inboxId,
        'title': title,
        'body': body,
      });
    } on PlatformException {
      // Ignore
    }
  }

  // ── Listening ───────────────────────────────────────────────────────────────
  void startListening() {
    if (_isListening) return;

    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final data = Map<String, dynamic>.from(event);
          if (data['type'] == 'inbox_action') {
            _handleInboxAction(
              data['action'] as String? ?? '',
              (data['inboxId'] as num?)?.toInt() ?? -1,
            );
          } else {
            _handleNotification(data);
          }
        }
      },
      onError: (error) {
        debugPrint('NotificationService Error: $error');
      },
    );

    _isListening = true;
  }

  /// Aksi cepat [Simpan]/[Abaikan] dari notifikasi Android — tanpa buka app.
  Future<void> _handleInboxAction(String action, int inboxId) async {
    if (inboxId <= 0) return;
    debugPrint('⚡ Inbox action: $action for #$inboxId');

    final item = await _inboxRepository.getById(inboxId);
    if (item == null || item.status != 'pending') return;

    if (action == 'dismiss') {
      await _inboxRepository.updateInboxItemStatus(inboxId, 'rejected');
      return;
    }

    if (action != 'save') return;

    // Parse data hasil ekstraksi.
    ParsedTransaction? parsed;
    if (item.extractedData != null) {
      try {
        parsed = ParsedTransaction.fromJson(jsonDecode(item.extractedData!));
      } catch (_) {}
    }
    if (parsed == null) return; // Tanpa data terstruktur → konfirmasi manual.

    // Cari/buat akun otomatis.
    final accounts = await _accountRepository.watchAllAccounts().first;
    final AccountMatchResult match;
    try {
      match = await AccountMatcher.findOrCreate(
        _accountRepository,
        accounts,
        item.sourceApp,
      );
    } catch (_) {
      return; // Tidak ada akun sama sekali → biarkan pending di app.
    }

    // Deteksi duplikat — bila ragu, biarkan user konfirmasi manual di app.
    final duplicates = await _transactionRepository.findPotentialDuplicates(
      accountId: match.accountId,
      amount: parsed.amount,
    );
    if (duplicates.isNotEmpty) return;

    await _transactionRepository.addTransaction(TransactionsCompanion(
      type: Value(parsed.type),
      amount: Value(parsed.amount),
      accountId: Value(match.accountId),
      merchant: Value(parsed.merchant),
      description: Value(item.rawText),
      transactionDate: Value(DateTime.now()),
      source: Value(item.source),
      sourceApp: Value(item.sourceApp),
      status: const Value('confirmed'),
      confidenceScore: Value(item.confidenceScore),
      isConfirmed: const Value(true),
      createdAt: Value(DateTime.now()),
    ));
    await _inboxRepository.updateInboxItemStatus(inboxId, 'confirmed');
    debugPrint('⚡ Auto-saved transaction #$inboxId from notification action.');
  }

  /// Memeriksa apakah paket app dikenali dan diaktifkan oleh pengguna
  /// di pengaturan notifikasi.
  static bool isPackageEnabled(String packageName, NotificationSettingsState s) {
    final pkg = packageName.toLowerCase();

    if (pkg.contains('ovo.id')) return s.isOvoEnabled;
    if (pkg.contains('gojek') || pkg.contains('gopay')) return s.isGopayEnabled;
    if (pkg.contains('id.dana')) return s.isDanaEnabled;
    if (pkg.contains('shopee')) return s.isShopeePayEnabled;
    if (pkg.contains('bri')) return s.isBrimoEnabled;
    if (pkg.contains('mandiri')) return s.isMandiriEnabled;
    if (pkg.contains('bca')) return s.isBcaEnabled;
    if (pkg.contains('bni')) return s.isBniEnabled;
    if (pkg.contains('seabank') || pkg.contains('bankbke')) {
      return s.isSeaBankEnabled;
    }
    if (pkg.contains('id.krom.bank')) return s.isKromEnabled;

    return false; // Paket tidak dikenali — jangan diproses.
  }

  Future<void> _handleNotification(Map<String, dynamic> data) async {
    final packageName = data['packageName'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final text = data['text'] as String? ?? '';

    debugPrint(
        '📬 Notif received: pkg=$packageName | title=$title | text=${text.substring(0, text.length.clamp(0, 80))}');

    // 1. Filter paket berdasarkan pengaturan per-app milik pengguna.
    if (!isPackageEnabled(packageName, _readSettings())) {
      debugPrint('Notification ignored: package disabled or unknown ($packageName)');
      return;
    }

    // 2. Rule engine lokal dulu — bekerja offline tanpa API key.
    ParsedTransaction? parsed;
    String parserUsed = '';
    try {
      final ruleResult =
          _ruleParser.parseNotification(packageName, title, text);
      if (ruleResult != null) {
        parsed = ruleResult;
        parserUsed = 'rule_engine';
        debugPrint(
            '[RuleEngine] ✅ Parsed: amount=${parsed.amount}, type=${parsed.type}, merchant=${parsed.merchant}');
      }
    } catch (e) {
      debugPrint('[RuleEngine] Error: $e');
    }

    // 3. Fallback ke Gemini hanya jika rule engine gagal mengenali transaksi.
    if (parsed == null) {
      final hasKey = await _gemini.hasApiKey();
      if (!hasKey) {
        debugPrint('Notification ignored: rule failed & no Gemini API key.');
        return;
      }

      debugPrint('[Gemini] Parsing notification from $packageName...');
      final result = await _gemini.parseNotification(
        packageName: packageName,
        title: title,
        text: text,
      );

      if (result == null) {
        debugPrint('Notification ignored: non-transaction or API error.');
        return;
      }

      final rawAmount = result['amount'];
      final amount = rawAmount is int
          ? rawAmount.toDouble()
          : (rawAmount is double ? rawAmount : double.tryParse(rawAmount.toString()));

      if (amount == null || amount <= 0) {
        debugPrint('Notification ignored: invalid amount from Gemini ($rawAmount).');
        return;
      }

      parsed = ParsedTransaction(
        amount: amount,
        merchant: result['merchant'] as String?,
        type: result['type'] as String? ?? 'expense',
        confidenceScore: 0.95,
      );
      parserUsed = 'gemini';
      debugPrint(
          '[Gemini] ✅ Parsed: amount=$amount, type=${parsed.type}, merchant=${parsed.merchant}');
    }

    // 4. Dedupe: notifikasi identik yang dikirim ulang Android dalam
    //    beberapa menit tidak boleh masuk Inbox dua kali.
    final rawText = 'Title: $title\nText: $text';
    final isDuplicate = await _inboxRepository.hasRecentSimilar(
      sourceApp: packageName,
      rawText: rawText,
    );
    if (isDuplicate) {
      debugPrint('[$parserUsed] Duplicate notification ignored.');
      return;
    }

    // 5. Simpan ke Inbox untuk dikonfirmasi pengguna (human-in-the-loop).
    final result = parsed; // salinan non-null untuk dipakai di closure.

    final item = InboxItemsCompanion(
      rawText: Value(rawText),
      source: const Value('notification'),
      sourceApp: Value(packageName),
      extractedData: Value(jsonEncode({
        ...result.toJson(),
        'parser': parserUsed,
      })),
      confidenceScore: Value(result.confidenceScore),
      status: const Value('pending'),
      detectedAt: Value(DateTime.now()),
    );

    await _inboxRepository.addInboxItem(item).then((inboxId) async {
      debugPrint('[$parserUsed] Notification saved to Inbox.');

      // Notifikasi Android dengan aksi cepat [Simpan]/[Abaikan].
      final currency = result.amount.toInt().toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
      await showInboxNotification(
        inboxId: inboxId,
        title: result.type == 'income'
            ? 'Uang masuk Rp $currency'
            : 'Pengeluaran Rp $currency',
        body: [
          if (result.merchant != null && result.merchant!.isNotEmpty)
            result.merchant!,
          'Simpan tanpa buka aplikasi?',
        ].join(' • '),
      );
    });
  }
}
