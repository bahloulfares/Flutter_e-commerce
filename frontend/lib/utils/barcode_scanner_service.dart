import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

// filtre les formats acceptés
class BarcodeScannerService {
  final Set<BarcodeFormat> allowedFormats = {
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.qrCode,
  };

  Future<String?> scanFromFilePath(String filePath) async {
    //cerrer un scanner temporaire
    final scanner = BarcodeScanner();
    try {
      //Crée un InputImage depuis le chemin du fichier
      //convertir le chemin en objet mlkit
      final inputImage = InputImage.fromFilePath(filePath);


      //Appelle processImage() → ML Kit
      //analyse l'image et détecte les codes
      final barcodes = await scanner.processImage(inputImage);

      //Parcourt la liste, vérifie le format, retourne la première valeur valide
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
