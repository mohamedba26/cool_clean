// lib/screens/scan_screen_merged.dart

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../routes.dart';
import '../services/openfoodfacts_service.dart';
import '../models/product.dart';
import '../theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  List<CameraDescription> cameras = [];

  final barcodeScanner = BarcodeScanner();
  final ofService = OpenFoodFactsService();
  final ImageLabeler imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.6),
  );
  final TextRecognizer textRecognizer = TextRecognizer();

  bool _processing = false;
  Timer? _resumeTimer;

  static const int kFallbackSeconds = 6;
  Timer? _fallbackTimer;

  // Animations (from scan_screen_2)
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Scan line animation
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Pulse animation for corners
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCameraPermission();
  }

  Future<void> _initCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission is required.")),
        );
      }
      return;
    }
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) throw "No cameras available";

      controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();
      await controller!.startImageStream(_processCameraImage);
      _startFallbackTimer();

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Camera error: $e")));
      }
    }
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: kFallbackSeconds), () async {
      await _tryImageFileScanFallback();
    });
  }

  void _resetFallbackTimer() {
    _fallbackTimer?.cancel();
    _startFallbackTimer();
  }

  Future<void> _tryImageFileScanFallback() async {
    if (controller == null || !controller!.value.isInitialized) {
      _startFallbackTimer();
      return;
    }

    try {
      await controller!.stopImageStream();
    } catch (_) {}

    XFile? xfile;
    try {
      debugPrint("Attempting fallback scan...");
      xfile = await controller!.takePicture();

      final inputImage = InputImage.fromFilePath(xfile.path);

      // 1. Try barcode
      final barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          debugPrint("Barcode detected: $code");
          await _onBarcodeDetected(code);
          return;
        }
      }
      debugPrint(
        "No barcode detected, proceeding with text and image analysis.",
      );

      // 2. Image labeling
      debugPrint("Attempting image labeling...");
      final labels = await imageLabeler.processImage(inputImage);
      String? topLabel;
      if (labels.isNotEmpty) {
        for (final label in labels) {
          debugPrint(
            "Label detected: ${label.label} | confidence: ${label.confidence}",
          );
        }
        topLabel = labels.first.label;
      } else {
        debugPrint("No labels detected in the image.");
      }

      // 3. Text recognition
      debugPrint("Trying text recognition...");
      final recognizedText = await textRecognizer.processImage(inputImage);
      String? bestText;

      if (recognizedText.blocks.isNotEmpty) {
        String? candidate;
        double minY = double.infinity;

        for (final block in recognizedText.blocks) {
          final text = block.text.trim().replaceAll('\n', ' ');
          if (text.length > 2 && block.boundingBox.top < minY) {
            minY = block.boundingBox.top;
            candidate = text;
          }
        }

        if (candidate != null) {
          bestText = candidate;
          debugPrint("Text detected (top-most): $bestText");
        }
      }

      // Prefer text result for product search
      if (bestText != null) {
        debugPrint("Searching for product with text: '$bestText'");
        final product = await ofService.searchByName(bestText);
        if (product != null) {
          debugPrint("Product found for text: '${product.name}'");
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            Routes.result,
            arguments: product,
          );
          return;
        } else {
          debugPrint('No product found for text "$bestText".');
        }
      } else {
        debugPrint("No usable text detected.");
      }

      // 4. Fallback to image label
      if (topLabel != null) {
        debugPrint(
          "Falling back to top image label. Searching for product with label: '$topLabel'",
        );
        final product = await ofService.searchByName(topLabel);
        if (product != null) {
          debugPrint("Product found for label: '${product.name}'");
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            Routes.result,
            arguments: product,
          );
          return;
        } else {
          debugPrint('No product found for label "$topLabel"');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No product found for "$topLabel" (or text "$bestText")',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No product, text, or labels could be identified.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Fallback capture error: $e');
    } finally {
      try {
        if (controller != null && controller!.value.isInitialized) {
          await controller!.startImageStream(_processCameraImage);
        }
      } catch (e) {
        debugPrint('Error restarting stream after fallback: $e');
      }
      _startFallbackTimer();
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_processing) return;
    _processing = true;

    try {
      final WriteBuffer buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      final bytes = buffer.done().buffer.asUint8List();

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation:
            InputImageRotationValue.fromRawValue(
              cameras.first.sensorOrientation,
            ) ??
            InputImageRotation.rotation0deg,
        format:
            InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

      final barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          await _onBarcodeDetected(code);
          return;
        }
      }

      _resetFallbackTimer();
    } catch (e) {
      // ignore, fallback will run eventually
    } finally {
      Future.delayed(const Duration(milliseconds: 150), () {
        _processing = false;
      });
    }
  }

  Future<void> _onBarcodeDetected(String code) async {
    try {
      await controller?.stopImageStream();
    } catch (_) {}

    if (!mounted) return;

    // Use nicer dialog style from scan_screen_2
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryStart),
              ),
              // const SizedBox(height: 16),
              // const Text(
              //   'Scanning product...',
              //   style: TextStyle(fontWeight: FontWeight.w600),
              // ),
            ],
          ),
        ),
      ),
    );

    try {
      final product = await ofService.fetchByBarcode(code);
      Navigator.of(context).pop();
      if (product != null) {
        Navigator.pushReplacementNamed(
          context,
          Routes.result,
          arguments: product,
        );
        return;
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Product not found: $code')));
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lookup error: $e')));
    } finally {
      _resumeScanningWithDelay();
    }
  }

  void _resumeScanningWithDelay() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 2), () async {
      try {
        if (controller != null && controller!.value.isInitialized) {
          await controller!.startImageStream(_processCameraImage);
        }
      } catch (e) {
        // ignore
      } finally {
        _processing = false;
        _startFallbackTimer();
      }
    });
  }

  // ---------- UI helpers from scan_screen_2 ----------

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.7;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                ..._buildAnimatedCorners(size),
                AnimatedBuilder(
                  animation: _scanLineAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: size * _scanLineAnimation.value,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.secondaryStart,
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryStart,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAnimatedCorners(double size) {
    return [
      _buildCorner(0, 0, [0, 0, 1, 1]),
      _buildCorner(0, size - 30, [1, 0, 0, 1]),
      _buildCorner(size - 30, 0, [0, 1, 1, 0]),
      _buildCorner(size - 30, size - 30, [1, 1, 0, 0]),
    ];
  }

  Widget _buildCorner(double top, double left, List<int> borders) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Positioned(
          top: top,
          left: left,
          child: Opacity(
            opacity: _pulseAnimation.value,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: borders[0] == 1
                      ? const BorderSide(color: Colors.white, width: 4)
                      : BorderSide.none,
                  right: borders[1] == 1
                      ? const BorderSide(color: Colors.white, width: 4)
                      : BorderSide.none,
                  bottom: borders[2] == 1
                      ? const BorderSide(color: Colors.white, width: 4)
                      : BorderSide.none,
                  left: borders[3] == 1
                      ? const BorderSide(color: Colors.white, width: 4)
                      : BorderSide.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.flash_on,
            label: 'Flash',
            onTap: () async {
              if (controller == null) return;
              try {
                final mode = controller!.value.flashMode;
                final newMode = mode == FlashMode.off
                    ? FlashMode.torch
                    : FlashMode.off;
                await controller!.setFlashMode(newMode);
                setState(() {});
              } catch (e) {
                debugPrint('Flash toggle error: $e');
              }
            },
          ),
          _buildControlButton(
            icon: Icons.camera_alt,
            label: 'Capture',
            onTap: _tryImageFileScanFallback,
            isPrimary: true,
          ),
          // _buildControlButton(
          //   icon: Icons.help_outline,
          //   label: 'Help',
          //   onTap: () {
          //     // TODO: show help dialog if desired
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isPrimary ? primaryGradient : null,
            color: isPrimary ? null : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (controller == null || !controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller!),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
        _buildScanOverlay(),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    barcodeScanner.close();
    textRecognizer.close();
    _resumeTimer?.cancel();
    _fallbackTimer?.cancel();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null) return;
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Scan Product",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(child: _buildCameraPreview()),
          _buildControls(),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: const Text(
              "Align the barcode within the frame.\nAuto-capture will trigger if no barcode is detected.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
