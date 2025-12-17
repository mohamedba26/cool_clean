// lib/screens/scan_screen.dart
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

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
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

  // fallback: if no barcode found after this many seconds, try capturing a photo
  static const int kFallbackSeconds = 6;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        ResolutionPreset.high, // use high for better detection
        enableAudio: false,
      );

      await controller!.initialize();

      // start the frame stream
      await controller!.startImageStream(_processCameraImage);

      // start fallback timer
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
    _fallbackTimer = Timer(Duration(seconds: kFallbackSeconds), () async {
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

    // stop stream
    try {
      await controller!.stopImageStream();
    } catch (_) {}

    XFile? xfile;

    try {
      debugPrint("Attempting fallback scan...");
      xfile = await controller!.takePicture();

      final inputImage = InputImage.fromFilePath(xfile.path);

      // 1. Try Barcode
      final barcodes = await barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          debugPrint("Barcode detected: $code");
          await _onBarcodeDetected(code);
          return;
        }
      }
      
      debugPrint("No barcode detected, proceeding with text and image analysis.");

      // 2. Always run image labeling and log the results.
      debugPrint("Attempting image labeling...");
      final labels = await imageLabeler.processImage(inputImage);
      String? topLabel;
      if (labels.isNotEmpty) {
        for (final label in labels) {
          debugPrint("Label detected: ${label.label}  | confidence: ${label.confidence}");
        }
        topLabel = labels.first.label;
      } else {
        debugPrint("No labels detected in the image.");
      }

      // 3. Try Text Recognition
      debugPrint("Trying text recognition...");
      final recognizedText = await textRecognizer.processImage(inputImage);
      String? bestText;

      // New heuristic: find the text block that's highest up in the image.
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

      // Prioritize text recognition results for product search
      if (bestText != null) {
        debugPrint("Searching for product with text: '$bestText'");
        final product = await ofService.searchByName(bestText);
        if (product != null) {
          debugPrint("Product found for text: '${product.name}'");
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

      // 4. If text recognition fails, fall back to using the top image label.
      if (topLabel != null) {
        debugPrint("Falling back to top image label. Searching for product with label: '$topLabel'");
        final product = await ofService.searchByName(topLabel);

        if (product != null) {
          debugPrint("Product found for label: '${product.name}'");
          Navigator.pushReplacementNamed(
            context,
            Routes.result,
            arguments: product,
          );
          return;
        } else {
          debugPrint('No product found for label "$topLabel"');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No product found for "$topLabel" (or text "$bestText")')),
          );
        }
      } else {
        // Only show this if both text and label searches have nothing to go on.
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No product, text, or labels could be identified.')),
        );
      }
    } catch (e) {
      debugPrint('Fallback capture error: $e');
    } finally {
      // restart stream
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
      // Combine plane bytes to a single Uint8List (as ML Kit expects)
      final WriteBuffer buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      final bytes = buffer.done().buffer.asUint8List();

      // Build metadata using new ML Kit API (InputImageMetadata)
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

      // no barcode: reset fallback timer to keep trying until fallback fires
      _resetFallbackTimer();
    } catch (e) {
      // continue — fallback will be attempted eventually
    } finally {
      // throttle a bit so we don't hog CPU
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final product = await ofService.fetchByBarcode(code);
      Navigator.of(context).pop(); // close loading

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
      } finally {
        _processing = false;
        _startFallbackTimer();
      }
    });
  }

  // Manual control bar (flash + capture)
  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (controller == null) return;
              try {
                final mode = controller!.value.flashMode;
                final newMode = mode == FlashMode.off
                    ? FlashMode.torch
                    : FlashMode.off;
                await controller!.setFlashMode(newMode);
                setState(() {});
              } catch (e) {
              }
            },
            icon: Icon(Icons.flash_on),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              // manual capture fallback (same as automatic fallback)
              await _tryImageFileScanFallback();
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capture'),
          ),
        ],
      ),
    );
  }

  Widget _cameraPreview() {
    if (controller == null || !controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controller!.value.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CameraPreview(controller!),
      ),
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
      appBar: AppBar(title: const Text("Scan Product")),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _cameraPreview(),
          _controls(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Point the camera at a barcode. If the stream fails, the app will take a photo automatically.",
            ),
          ),
        ],
      ),
    );
  }
}
