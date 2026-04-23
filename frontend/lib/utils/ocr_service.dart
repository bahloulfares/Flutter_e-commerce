import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  //instance réutilisable (pas recréée à chaque appel, économise la mémoire)
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extrait les informations d'une image d'étiquette produit.
  /// Retourne: designation, marque, prix, reference (best-effort)
  Future<Map<String, String>> extractInfoFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    
    /*processImage() → retourne un arbre :
    RecognizedText → Block → Line → Element*/
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    String designation = '';
    String marque = '';
    String prix = '';
    String reference = '';

    // Regex patterns
    final priceRegex = RegExp(r'\d+[,.]\d{2}');
    final refRegex = RegExp(r'(?:ref|réf|reference|code)[:\s]*([A-Z0-9\-]+)',
        caseSensitive: false);
    final marqueKeywords = ['marque', 'brand', 'by'];

    final allLines = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) allLines.add(text);
      }
    }

    for (final text in allLines) {
      final lower = text.toLowerCase();

      // Prix
      if (prix.isEmpty && priceRegex.hasMatch(text)) {
        prix = priceRegex.firstMatch(text)!.group(0)!.replaceAll(',', '.');
      }

      // Référence explicite
      if (reference.isEmpty && refRegex.hasMatch(text)) {
        reference = refRegex.firstMatch(text)!.group(1) ?? '';
      }

      // Marque
      if (marque.isEmpty &&
          marqueKeywords.any((kw) => lower.contains(kw))) {
        // Prendre la partie après le mot-clé
        final parts = text.split(RegExp(r'[:\s]+'));
        if (parts.length > 1) marque = parts.last.trim();
      }

      // Désignation : première ligne significative (>3 chars, pas un prix, pas une ref)
      if (designation.isEmpty &&
          text.length > 3 &&
          !priceRegex.hasMatch(text) &&
          !refRegex.hasMatch(text)) {
        designation = text;
      }
    }

    // Fallback: si pas de marque trouvée par mot-clé, prendre la 2e ligne
    if (marque.isEmpty && allLines.length > 1) {
      marque = allLines[1];
    }

    return {
      'designation': designation,
      'marque': marque,
      'prix': prix,
      'reference': reference,
      'rawText': allLines.join('\n'),
    };
  }

  void dispose() {
    _textRecognizer.close();
  }
}
