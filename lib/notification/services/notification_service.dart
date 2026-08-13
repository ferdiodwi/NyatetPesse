import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:nyatet_pesse/data/database/app_database.dart';
import 'package:nyatet_pesse/data/repositories/inbox_repository.dart';
import 'package:nyatet_pesse/features/inbox/domain/services/transaction_parser.dart';
import 'package:nyatet_pesse/data/repositories/repository_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(inboxRepositoryProvider),
    TransactionParser(),
  );
});

class NotificationService {
  static const EventChannel _eventChannel = EventChannel('com.example.nyatet_pesse/notification_event');
  
  final InboxRepository _inboxRepository;
  final TransactionParser _parser;
  bool _isListening = false;

  NotificationService(this._inboxRepository, this._parser);

  void startListening() {
    if (_isListening) return;
    
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        _handleNotification(Map<String, dynamic>.from(event));
      }
    }, onError: (error) {
      print('NotificationService Error: $error');
    });
    
    _isListening = true;
  }

  Future<void> _handleNotification(Map<String, dynamic> data) async {
    final packageName = data['packageName'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final text = data['text'] as String? ?? '';
    
    final parsedTransaction = _parser.parseNotification(packageName, title, text);
    
    // Only save if the parser successfully identified it as a potential transaction
    if (parsedTransaction != null) {
      final item = InboxItemsCompanion(
        rawText: Value('Title: $title\nText: $text'),
        source: const Value('notification'),
        sourceApp: Value(packageName),
        extractedData: Value(jsonEncode(parsedTransaction.toJson())),
        confidenceScore: Value(parsedTransaction.confidenceScore),
        status: const Value('pending'),
        detectedAt: Value(DateTime.now()),
      );
      
      await _inboxRepository.addInboxItem(item);
      print('Notification saved to Inbox: \${parsedTransaction.amount}');
    } else {
      print('Notification ignored (not a valid transaction).');
    }
  }
}
