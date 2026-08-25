import 'package:flutter_test/flutter_test.dart';
import 'package:nyatet_pesse/features/inbox/domain/services/transaction_parser.dart';

void main() {
  final parser = TransactionParser();

  group('TransactionParser.parseNotification', () {
    test('parses SeaBank incoming transfer (income + sender)', () {
      final result = parser.parseNotification(
        'com.b1.dbseabank',
        'Transfer Masuk',
        'Kamu menerima transfer saldo senilai Rp10.000 dari MUHAMMAD ZIDANE JULIAN SAPUTRA.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 10000);
      expect(result.type, 'income');
      expect(result.merchant, 'MUHAMMAD ZIDANE JULIAN SAPUTRA');
      expect(result.confidenceScore, 0.9);
    });

    test('parses SeaBank outgoing transfer (expense + recipient)', () {
      final result = parser.parseNotification(
        'com.b1.dbseabank',
        'SeaBank',
        'Kamu melakukan transfer senilai Rp250.000 kepada Budi pada 12/08/2026.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 250000);
      expect(result.type, 'expense');
      expect(result.merchant, 'Budi');
    });

    test('parses DANA payment with merchant', () {
      final result = parser.parseNotification(
        'id.dana',
        'DANA',
        'Pembayaran ke Tokopedia berhasil. Rp150.000 terpotong dari saldo DANA.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 150000);
      expect(result.type, 'expense');
      expect(result.merchant, 'Tokopedia');
      expect(result.confidenceScore, 0.8);
    });

    test('parses GoPay deduction with merchant', () {
      final result = parser.parseNotification(
        'com.gojek.app',
        'GoPay',
        'GoPay kamu terpotong Rp15.000 untuk Indomaret.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 15000);
      expect(result.type, 'expense');
      expect(result.merchant, 'Indomaret');
    });

    test('parses BCA transfer with large formatted amount', () {
      final result = parser.parseNotification(
        'com.bca',
        'BCA Mobile',
        'Anda melakukan transfer Rp2.500.000 kepada Budi Santoso berhasil',
      );

      expect(result, isNotNull);
      expect(result!.amount, 2500000);
      expect(result.type, 'expense');
      expect(result.merchant, 'Budi Santoso');
    });

    test('handles decimal amounts', () {
      final result = parser.parseNotification(
        'id.dana',
        'DANA',
        'Pembayaran ke Kopi Kenangan berhasil. Rp10.000,50 terpotong.',
      );

      expect(result, isNotNull);
      expect(result!.amount, closeTo(10000.5, 0.001));
    });

    test('rejects OTP notifications', () {
      final result = parser.parseNotification(
        'id.dana',
        'DANA',
        'Kode OTP Anda adalah 123456. Jangan berikan kode ini kepada siapa pun.',
      );

      expect(result, isNull);
    });

    test('rejects promo notifications', () {
      final result = parser.parseNotification(
        'ovo.id',
        'OVO',
        'Promo! Cashback 50% untuk transaksi di merchant favorit!',
      );

      expect(result, isNull);
    });

    test('rejects notifications without an Rp-prefixed amount', () {
      final result = parser.parseNotification(
        'com.gojek.app',
        'Gojek',
        'Order #12345 sudah dikirim oleh kurir, nomor resi 9876543210.',
      );

      expect(result, isNull);
    });
  });
}
