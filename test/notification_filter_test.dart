import 'package:flutter_test/flutter_test.dart';
import 'package:nyatet_pesse/features/settings/presentation/providers/settings_provider.dart';
import 'package:nyatet_pesse/notification/services/notification_service.dart';

void main() {
  group('NotificationService.isPackageEnabled', () {
    test('allows all recognized packages by default', () {
      final settings = NotificationSettingsState();

      expect(NotificationService.isPackageEnabled('id.dana', settings), isTrue);
      expect(NotificationService.isPackageEnabled('ovo.id', settings), isTrue);
      expect(NotificationService.isPackageEnabled('com.gojek.app', settings), isTrue);
      expect(NotificationService.isPackageEnabled('com.shopee.id', settings), isTrue);
      expect(NotificationService.isPackageEnabled('id.co.bri.brimo', settings), isTrue);
      expect(NotificationService.isPackageEnabled('id.co.bankmandiri.livin', settings), isTrue);
      expect(NotificationService.isPackageEnabled('com.bca.mybca', settings), isTrue);
      expect(NotificationService.isPackageEnabled('id.co.bni.mobilebanking', settings), isTrue);
      expect(NotificationService.isPackageEnabled('com.bke.seabank', settings), isTrue);
      expect(NotificationService.isPackageEnabled('id.krom.bank', settings), isTrue);
    });

    test('blocks a package when its toggle is disabled', () {
      final settings = NotificationSettingsState(isBcaEnabled: false);

      expect(NotificationService.isPackageEnabled('com.bca', settings), isFalse);
      expect(NotificationService.isPackageEnabled('com.bca.mybca', settings), isFalse);
    });

    test('blocking one bank does not affect others', () {
      final settings = NotificationSettingsState(isSeaBankEnabled: false);

      expect(NotificationService.isPackageEnabled('com.bke.seabank', settings), isFalse);
      expect(NotificationService.isPackageEnabled('com.bca', settings), isTrue);
    });

    test('rejects unrecognized packages', () {
      final settings = NotificationSettingsState();

      expect(NotificationService.isPackageEnabled('com.whatsapp', settings), isFalse);
      expect(NotificationService.isPackageEnabled('', settings), isFalse);
    });

    test('match is case-insensitive', () {
      final settings = NotificationSettingsState();

      expect(NotificationService.isPackageEnabled('ID.DANA', settings), isTrue);
    });
  });
}
