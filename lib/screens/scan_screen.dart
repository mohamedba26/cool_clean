// lib/screens/scan_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';

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
      debugPrint("Camera init error: $e");
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
      debugPrint('Fallback timer fired — trying full-photo scan');
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

    // stop stream to take a high-quality picture
    try {
      await controller!.stopImageStream();
    } catch (_) {}

    XFile? xfile;
    try {
      xfile = await controller!.takePicture();
      debugPrint('Fallback picture saved: ${xfile.path}');
      final inputImage = InputImage.fromFilePath(xfile.path);
      final barcodes = await barcodeScanner.processImage(inputImage);
      debugPrint('Fallback file barcodes: ${barcodes.length}');
      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          await _onBarcodeDetected(code);
          return;
        }
      } else {
        // no barcode in file result; resume streaming
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No barcode detected in photo — try another product or move closer.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Fallback capture error: $e');
    } finally {
      // restart stream and fallback timer
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

    // DEBUG prints to help you see what's happening
    debugPrint("Frame received: ${image.width}x${image.height}");
    debugPrint("Image format raw: ${image.format.raw}");

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
      debugPrint("Barcodes detected (stream): ${barcodes.length}");

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
      debugPrint("Frame processing error: $e");
      // continue — fallback will be attempted eventually
    } finally {
      // throttle a bit so we don't hog CPU
      Future.delayed(const Duration(milliseconds: 150), () {
        _processing = false;
      });
    }
  }

  Future<void> _onBarcodeDetected(String code) async {
    debugPrint("Detected barcode: $code");

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
        debugPrint('resume error: $e');
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
                debugPrint('Flash error: $e');
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
