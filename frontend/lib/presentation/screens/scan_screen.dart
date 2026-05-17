import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _isHandlingResult = false;
  bool _isTorchOn = false;
  String _statusMessage = 'place_barcode_in_frame'.tr;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.stop();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isHandlingResult) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _isHandlingResult = true;
        setState(() {
          _statusMessage = 'code_detected'.tr.replaceAll('{code}', raw);
        });
        Navigator.of(context).pop(raw);
        return;
      }
    }

    if (!_isHandlingResult && mounted) {
      setState(() {
        _statusMessage = 'no_readable_code_retry'.tr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('barcode_scan_title'.tr),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () {
              _controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'flash'.tr,
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'close'.tr,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'camera_access_unavailable'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.message ??
                            'camera_permissions_retry'.tr,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _controller.start(),
                        icon: const Icon(Icons.refresh),
                        label: Text('reessayer'.tr),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
