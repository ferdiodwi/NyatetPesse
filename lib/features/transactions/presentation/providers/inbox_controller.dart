import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyatet_pesse/core/services/notification_service.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/inbox_repository.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/settings_provider.dart';
import 'package:nyatet_pesse/features/transactions/domain/parsers/notification_parser.dart';

final inboxItemsProvider = StreamProvider<List<InboxItem>>((ref) {
  final repository = ref.watch(inboxRepositoryProvider);
  return repository.watchPendingInboxItems();
});

final inboxControllerProvider = Provider<InboxController>((ref) {
  return InboxController(
    ref.watch(inboxRepositoryProvider),
    ref,
  );
});

class InboxController {
  final InboxRepository _repository;
  final ProviderRef _ref;
  StreamSubscription? _subscription;

  InboxController(this._repository, this._ref) {
    _initListener();
  }

  void _initListener() {
    _subscription = NotificationService.notificationStream.listen((data) async {
      final settings = _ref.read(notificationSettingsProvider);

      // Check if package is enabled in settings
      bool isAllowed = false;
      if (data.packageName == 'com.bca' || data.packageName == 'com.bca.mybca') {
        isAllowed = settings.isBcaEnabled;
      } else if (data.packageName == 'id.co.bankmandiri.livin') {
        isAllowed = settings.isMandiriEnabled;
      } else if (data.packageName == 'id.dana') {
        isAllowed = settings.isDanaEnabled;
      } else if (data.packageName == 'com.gojek.app' || data.packageName == 'com.gopay.app') {
        isAllowed = settings.isGopayEnabled;
      } else if (data.packageName == 'ovo.id') {
        isAllowed = settings.isOvoEnabled;
      } else if (data.packageName == 'com.shopee.id' || data.packageName == 'com.shopeepay.id') {
        isAllowed = settings.isShopeePayEnabled;
      } else if (data.packageName == 'id.co.bri.brimo') {
        isAllowed = settings.isBrimoEnabled;
      } else if (data.packageName == 'co.id.bni.mobilebanking' || data.packageName == 'id.co.bni.mobilebanking') {
        isAllowed = settings.isBniEnabled;
      } else if (data.packageName == 'com.bke.seabank') {
        isAllowed = settings.isSeaBankEnabled;
      } else if (data.packageName == 'id.krom.bank') {
        isAllowed = settings.isKromEnabled;
      }

      if (isAllowed) {
        // Try parsing the notification
        final parsed = NotificationParser.parse(data);
        
        String? extractedDataJson;
        double? confidence;
        String sourceApp = data.packageName;
        
        if (parsed != null) {
          extractedDataJson = jsonEncode({
            'amount': parsed.amount,
            'type': parsed.type,
            'source': parsed.source,
          });
          confidence = 0.9; // Rule-based is usually high confidence
          sourceApp = parsed.source;
        }

        // Save to inbox
        await _repository.addInboxItem(InboxItemsCompanion(
          rawText: Value('${data.title}\n${data.text}'),
          source: const Value('notification'),
          sourceApp: Value(sourceApp),
          extractedData: Value(extractedDataJson),
          confidenceScore: Value(confidence),
          status: const Value('pending'),
          detectedAt: Value(data.postTime),
        ));
      }
    });
  }

  Future<void> confirmItem(int id) async {
    // In the future, this will also insert to Transactions table.
    // For now, just mark it as confirmed in the Inbox.
    await _repository.updateInboxItemStatus(id, 'confirmed');
  }

  Future<void> rejectItem(int id) async {
    await _repository.updateInboxItemStatus(id, 'rejected');
  }

  void dispose() {
    _subscription?.cancel();
  }
}
