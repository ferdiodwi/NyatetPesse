import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:nyatet_pesse/core/services/gemini_service.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/inbox_repository.dart';
import 'package:nyatet_pesse/features/inbox/domain/models/parsed_transaction.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/features/security/presentation/providers/security_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(ref.watch(secureStorageProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(inboxRepositoryProvider),
    ref.watch(geminiServiceProvider),
  );
});

class NotificationService {
  static const EventChannel _eventChannel =
      EventChannel('com.example.nyatet_pesse/notification_event');

  final InboxRepository _inboxRepository;
  final GeminiService _gemini;
  bool _isListening = false;

  NotificationService(this._inboxRepository, this._gemini);

  void startListening() {
    if (_isListening) return;

    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          _handleNotification(Map<String, dynamic>.from(event));
        }
      },
      onError: (error) {
        debugPrint('NotificationService Error: $error');
      },
    );

    _isListening = true;
  }

  Future<void> _handleNotification(Map<String, dynamic> data) async {
    final packageName = data['packageName'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final text = data['text'] as String? ?? '';

    // Log setiap notifikasi yang masuk — untuk debugging
    debugPrint('📬 Notif received: pkg=$packageName | title=$title | text=${text.substring(0, text.length.clamp(0, 80))}');

    // Cek apakah ini paket keuangan yang dikenali
    const allowedPackages = [
      'id.dana', 'ovo.id', 'com.gojek.app', 'com.shopee.id',
      'com.bca', 'com.bankmandiri', 'seabank', 'bankbke',
      'com.bni', 'com.bri', 'com.cimb', 'com.ocbc',
      'id.co.mandiri', 'com.permatabank', 'com.linkaja',
    ];

    bool isAllowed = false;
    for (final pkg in allowedPackages) {
      if (packageName.toLowerCase().contains(pkg)) {
        isAllowed = true;
        break;
      }
    }

    if (!isAllowed) {
      debugPrint('Notification ignored: unknown package ($packageName)');
      return;
    }

    // Periksa API key tersedia
    final hasKey = await _gemini.hasApiKey();
    if (!hasKey) {
      debugPrint('Notification ignored: Gemini API key not set.');
      return;
    }

    // Kirim ke Gemini Flash
    debugPrint('[Gemini] Parsing notification from $packageName...');
    final result = await _gemini.parseNotification(
      packageName: packageName,
      title: title,
      text: text,
    );

    if (result == null) {
      debugPrint('Notification ignored: Gemini returned null (non-transaction or API error).');
      return;
    }

    // Konversi hasil Gemini ke ParsedTransaction
    final rawAmount = result['amount'];
    final amount = rawAmount is int
        ? rawAmount.toDouble()
        : (rawAmount is double ? rawAmount : double.tryParse(rawAmount.toString()));

    if (amount == null || amount <= 0) {
      debugPrint('Notification ignored: invalid amount from Gemini ($rawAmount).');
      return;
    }

    final parsed = ParsedTransaction(
      amount: amount,
      merchant: result['merchant'] as String?,
      type: result['type'] as String? ?? 'expense',
      confidenceScore: 0.95,
    );

    debugPrint('[Gemini] ✅ Parsed: amount=$amount, type=${parsed.type}, merchant=${parsed.merchant}');

    // Simpan ke Inbox
    final item = InboxItemsCompanion(
      rawText: Value('Title: $title\nText: $text'),
      source: const Value('notification'),
      sourceApp: Value(packageName),
      extractedData: Value(jsonEncode(parsed.toJson())),
      confidenceScore: Value(parsed.confidenceScore),
      status: const Value('pending'),
      detectedAt: Value(DateTime.now()),
    );

    await _inboxRepository.addInboxItem(item);
    debugPrint('[Gemini] Notification saved to Inbox.');
  }
}
