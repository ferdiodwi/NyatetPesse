import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nyatet_pesse/core/services/ocr_service.dart';
import 'package:nyatet_pesse/features/transactions/domain/parsers/ocr_parser.dart';
import 'package:nyatet_pesse/features/transactions/presentation/screens/add_transaction_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndInitCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
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
    _cameraController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
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
              initialMerchant: parsed.merchant,
              initialDate: parsed.date,
              initialNote: 'RAW OCR:\n${parsed.rawText}',
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

                    // Flash Toggle (Placeholder or functional later)
                    IconButton(
                      onPressed: () {
                         // Optional: Implement flash toggle
                      },
                      icon: const Icon(Icons.flash_off, color: Colors.white, size: 32),
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
