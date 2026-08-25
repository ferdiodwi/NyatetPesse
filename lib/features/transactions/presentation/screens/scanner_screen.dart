import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nyatet_pesse/core/services/ocr_service.dart';
import 'package:nyatet_pesse/features/transactions/domain/parsers/ocr_parser.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:nyatet_pesse/notification/services/notification_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndInitCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    _ocrService.dispose();
    super.dispose();
  }

  /// Lepas kamera sepenuhnya — dipanggil saat tab ditinggalkan (widget
  /// di-unmount oleh IndexedStack kondisional) dan saat app ke background.
  /// Flag di-reset SEBELUM await agar UI tidak pernah merender preview
  /// dengan controller yang sudah null/di-dispose (race condition).
  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    if (controller == null && !_isCameraInitialized) return;
    _cameraController = null;
    _isCameraInitialized = false;
    if (mounted) setState(() {});
    await controller?.dispose();
    debugPrint('📷 Camera DISPOSED (released)');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _isCameraPermissionGranted) {
      _initCamera(cameraController.description);
    }
  }

  Future<void> _checkPermissionAndInitCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isCameraPermissionGranted = true);
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Find the back camera
        final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        await _initCamera(backCamera);
      }
    } else {
      setState(() => _isCameraPermissionGranted = false);
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    // Hindari double-init: lepaskan controller lama bila ada.
    await _disposeCamera();

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _cameraController = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      debugPrint('📷 Camera INITIALIZED');
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      _cameraController = null;
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      
      // Auto-turn off flash after capturing
      if (_isFlashOn) {
        setState(() {
          _isFlashOn = false;
        });
        await _cameraController!.setFlashMode(FlashMode.off);
      }

      await _processImageFile(File(image.path));
    } catch (e) {
      _showError('Gagal mengambil gambar: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isProcessing = true);
      await _processImageFile(File(image.path));
    } catch (e) {
      _showError('Gagal memilih gambar dari galeri: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImageFile(File file) async {
    try {
      final geminiService = ref.read(geminiServiceProvider);
      final hasGeminiKey = await geminiService.hasApiKey();

      double? finalAmount;
      String? finalType;
      String? finalMerchant;
      DateTime? finalDate;
      String finalNote = '';

      if (hasGeminiKey) {
        debugPrint('Menggunakan Gemini OCR...');
        try {
          final result = await geminiService.parseReceiptImage(file);
          
          if (result != null) {
            final rawAmount = result['amount'];
            if (rawAmount != null) {
              finalAmount = double.tryParse(rawAmount.toString());
            }
            finalType = result['type'] as String?;
            finalMerchant = result['merchant'] as String?;
            
            if (result['date'] != null) {
              try {
                finalDate = DateTime.parse(result['date']);
              } catch (_) {}
            }
            finalNote = 'Diproses oleh Gemini AI✨';
          }
        } catch (e) {
          debugPrint('Gemini Exception caught: $e');
          if (mounted) {
            final msg = e.toString().contains('API_QUOTA_EXCEEDED') 
                ? 'Kuota AI Gemini harian Anda telah habis.' 
                : 'Koneksi ke AI bermasalah.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$msg Menggunakan OCR lokal...'),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // Fallback ke ML Kit jika Gemini gagal / tidak ada API Key
      if (finalAmount == null) {
        debugPrint('Fallback ke ML Kit OCR lokal...');
        final rawText = await _ocrService.extractTextFromImage(file);

        if (rawText != null && rawText.isNotEmpty) {
          final parsed = OcrParser.parse(rawText);
          finalAmount = parsed.amount;
          finalType = parsed.type;
          finalMerchant = parsed.merchant;
          finalDate = parsed.date;
          finalNote = 'RAW OCR:\n${parsed.rawText}';
        }
      }

      if (!mounted) return;

      if (finalAmount != null || finalMerchant != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTransactionScreen(
              initialAmount: finalAmount,
              initialType: finalType ?? 'EXPENSE',
              initialMerchant: finalMerchant,
              initialDate: finalDate,
              initialNote: finalNote,
            ),
          ),
        );
      } else {
        _showError('Gagal membaca teks dari gambar. Pastikan struk jelas.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If not granted, show permission request UI
    if (!_isCameraPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Struk')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Akses kamera diperlukan untuk memindai struk.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermissionAndInitCamera,
                child: const Text('Beri Akses Kamera'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isCameraInitialized && _cameraController != null)
              SizedBox.expand(
                child: CameraPreview(_cameraController!),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            
            // Viewfinder Overlay (Dimmed background with clear center)
            if (_isCameraInitialized && !_isProcessing)
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.5),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut,
                      ), // This one will handle background filter
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.5,
                        decoration: BoxDecoration(
                          color: Colors.red, // Any color works, will be cut out
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Viewfinder Border Guidelines
            if (_isCameraInitialized && !_isProcessing)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

            // Top Header
            if (!_isProcessing)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'Posisikan struk di dalam kotak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Controls
            if (!_isProcessing)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery Button
                    IconButton(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                      tooltip: 'Pilih dari Galeri',
                    ),

                    // Capture Button
                    GestureDetector(
                      onTap: _captureAndProcess,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Flash Toggle
                    IconButton(
                      onPressed: () async {
                        if (_cameraController != null && _cameraController!.value.isInitialized) {
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                          });
                          await _cameraController!.setFlashMode(
                            _isFlashOn ? FlashMode.torch : FlashMode.off,
                          );
                        }
                      },
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off, 
                        color: _isFlashOn ? Theme.of(context).colorScheme.primary : Colors.white, 
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

            // Processing Indicator Overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Memproses gambar...',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
