import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKeyStorageKey = 'gemini_api_key';
  static const String _modelStorageKey = 'gemini_cached_model_v2';
  static const String _baseApiUrl = 'https://generativelanguage.googleapis.com/v1beta';

  final FlutterSecureStorage _storage;

  GeminiService(this._storage);

  // ── API Key Management ────────────────────────────────────────────────────────
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: _apiKeyStorageKey, value: key.trim());
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyStorageKey);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyStorageKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  // ── Notification Parsing ──────────────────────────────────────────────────────
  /// Returns a map with keys: amount, type, merchant
  /// Returns null if the request fails or there is no API key.
  Future<Map<String, dynamic>?> parseNotification({
    required String packageName,
    required String title,
    required String text,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final modelName = await _getBestModel(apiKey);
    final url = '$_baseApiUrl/models/$modelName:generateContent';

    const prompt = '''
Kamu adalah parser transaksi keuangan untuk aplikasi catatan keuangan Indonesia.

Tugasmu: Ekstrak informasi transaksi dari notifikasi bank atau e-wallet berikut.

ATURAN:
1. "amount" = nominal uang dalam angka bulat (contoh: 50000, bukan "Rp 50.000")
2. "type" = "income" jika uang masuk/diterima, "expense" jika uang keluar/dibayar/ditransfer, "transfer" jika top up saldo
3. "merchant" = nama toko, penerima, atau pengirim uang. Jika tidak ada, isi null.
4. Jika ini BUKAN notifikasi transaksi keuangan (promo, OTP, info saldo, iklan), kembalikan: {"is_transaction": false}
5. Selalu kembalikan JSON valid tanpa markdown atau kode block.

Format response yang benar:
{"is_transaction": true, "amount": 50000, "type": "expense", "merchant": "Indomaret"}
atau
{"is_transaction": false}
''';

    final userMessage = '''
Package: $packageName
Judul: $title
Isi: $text
''';

    try {
      final response = await http
          .post(
            Uri.parse('$url?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {'text': userMessage},
                  ],
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[Gemini] HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (rawText == null) return null;

        // Clean up potential markdown wrapping
        final cleaned = rawText
            .toString()
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        debugPrint('[Gemini] Raw AI Response: $cleaned');

        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
        if (parsed['is_transaction'] == false) return null;
        return parsed;
      } else {
        // Log the full error body so we can see what went wrong
        debugPrint('[Gemini] ❌ Error ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
        return null;
      }
    } catch (e) {
      debugPrint('[Gemini] ❌ Exception: $e');
      return null;
    }

    return null;
  }

  // ── Auto-Detect Latest Model ────────────────────────────────────────────────
  Future<String> _getBestModel(String apiKey) async {
    // 1. Cek cache (agar tidak perlu request ke server tiap ada notif)
    final cached = await _storage.read(key: _modelStorageKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 2. Fetch dari Google API jika belum ada di cache
    try {
      debugPrint('[Gemini] Mengambil daftar model terbaru dari Google...');
      final response = await http.get(
        Uri.parse('$_baseApiUrl/models?key=$apiKey'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;

        String? bestModel;
        // Cari model "flash" yang mendukung generateContent
        for (final m in models) {
          final name = m['name'] as String;
          final methods = m['supportedGenerationMethods'] as List?;
          if (name.contains('flash') && 
              !name.contains('tts') && 
              !name.contains('preview') &&
              methods != null && 
              methods.contains('generateContent')) {
            bestModel = name.replaceFirst('models/', '');
          }
        }

        if (bestModel != null) {
          debugPrint('[Gemini] ✅ Model dinamis terpilih: $bestModel');
          await _storage.write(key: _modelStorageKey, value: bestModel);
          return bestModel;
        }
      }
    } catch (e) {
      debugPrint('[Gemini] ⚠️ Gagal auto-detect model: $e');
    }

    // 3. Fallback jika internet bermasalah saat deteksi awal
    return 'gemini-3.6-flash';
  }

  // Fungsi untuk mereset model (dipanggil jika ingin refresh manual atau jika key dihapus)
  Future<void> clearCachedModel() async {
    await _storage.delete(key: _modelStorageKey);
  }
}
