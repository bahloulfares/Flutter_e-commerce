import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScannerService {
  final Set<BarcodeFormat> allowedFormats = {
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.qrCode,
  };

  Future<String?> scanFromFilePath(String filePath) async {
    final scanner = BarcodeScanner();
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final barcodes = await scanner.processImage(inputImage);

      for (final barcode in barcodes) {
        if (!allowedFormats.contains(barcode.format)) continue;
        final raw = barcode.rawValue?.trim();
        if (raw != null && raw.isNotEmpty) {
          return raw;
        }
      }

      return null;
    } finally {
      await scanner.close();
    }
  }
}
