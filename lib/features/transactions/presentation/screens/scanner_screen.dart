import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nyatet_pesse/core/services/ocr_service.dart';
import 'package:nyatet_pesse/features/transactions/domain/parsers/ocr_parser.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/add_transaction_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _isProcessing = true;
      });

      final file = File(image.path);
      final rawText = await _ocrService.extractTextFromImage(file);

      if (!mounted) return;

      if (rawText != null && rawText.isNotEmpty) {
        final parsed = OcrParser.parse(rawText);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTransactionScreen(
              initialAmount: parsed.amount,
              initialType: parsed.type,
              initialNote: 'Merchant: ${parsed.merchant ?? "-"}\n\nRAW OCR:\n${parsed.rawText}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membaca teks dari gambar')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Struk & Bukti TF'),
      ),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses gambar (ML Kit)...'),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.document_scanner,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Otomatisasi Catatan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pindai struk belanja atau pilih screenshot bukti transfer dari galeri. NyatetPesse akan mencoba menebak nominal secara otomatis secara offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _processImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Ambil Foto Kamera'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _processImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pilih dari Galeri'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
