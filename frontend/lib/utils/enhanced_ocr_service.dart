import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class EnhancedOcrService {
  final Map<String, TextRecognizer> _recognizerCache = {};

  /// Obtient un TextRecognizer avec la langue spécifiée (cache)
  TextRecognizer _getRecognizer([String? language]) {
    final key = language ?? 'default';
    _recognizerCache[key] ??= language != null
        ? TextRecognizer(script: TextRecognitionScript.latin)
        : TextRecognizer();
    return _recognizerCache[key]!;
  }

  /// Extraction avancée avec prétraitement et analyse contextuelle
  Future<Map<String, dynamic>> extractProductInfo({
    required File imageFile,
    String? language,
    bool enablePreprocessing = true,
  }) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizer = _getRecognizer(language);

      final recognizedText = await recognizer.processImage(inputImage);

      // Analyse avancée
      final analysis = _analyzeTextStructure(recognizedText);

      return {
        'success': true,
        'confidence': analysis['confidence'],
        'extractedData': {
          'designation': analysis['designation'],
          'marque': analysis['marque'],
          'prix': analysis['prix'],
          'reference': analysis['reference'],
          'description': analysis['description'],
          'category_hints': analysis['categoryHints'],
        },
        'rawText': analysis['rawText'],
        'blocks': analysis['blocks']
            .map((block) => {
                  'text': block.text,
                  'confidence': block.confidence ?? 0.0,
                  'lines': block.lines.map((line) => line.text).toList(),
                })
            .toList(),
        'processing_metadata': {
          'timestamp': DateTime.now().toIso8601String(),
          'language': language,
          'preprocessing': enablePreprocessing,
          'block_count': analysis['blocks'].length,
          'line_count': recognizedText.blocks
              .fold<int>(0, (sum, block) => sum + block.lines.length),
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'extractedData': null,
      };
    }
  }

  /// Analyse structurelle du texte reconnu
  Map<String, dynamic> _analyzeTextStructure(RecognizedText recognizedText) {
    final allLines = <String>[];
    final allBlocks = <TextBlock>[];

    // Collecte structurée
    for (final block in recognizedText.blocks) {
      allBlocks.add(block);
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) allLines.add(text);
      }
    }

    // Patterns d'extraction
    final pricePattern = RegExp(r'(\d+[,.]\d{2})\s*(?:TND|DT|€|\$|Dinars?)?',
        caseSensitive: false);
    final refPattern = RegExp(
        r'(?:ref|réf|reference|code|r\.?)\s*[:\-]?\s*([A-Z0-9\-]{4,})',
        caseSensitive: false);
    final brandPatterns = [
      RegExp(r'(?:marque|brand|marque|fabriqué par|by)\s*[:\-]?\s*(.+)',
          caseSensitive: false),
      RegExp(r'^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:®|™|©)',
          caseSensitive: false),
    ];

    String? prix, reference, marque, designation, description;
    final categoryHints = <String>[];

    // Extraction avec scoring de confiance
    for (final line in allLines) {
      final lowerLine = line.toLowerCase();

      // Prix (plusieurs tentatives)
      if (prix == null) {
        final priceMatch = pricePattern.firstMatch(line);
        if (priceMatch != null) {
          prix = priceMatch.group(1)?.replaceAll(',', '.') ?? '';
        }
      }

      // Référence
      if (reference == null) {
        final refMatch = refPattern.firstMatch(line);
        if (refMatch != null) {
          reference = refMatch.group(1)?.trim() ?? '';
        }
      }

      // Marque
      if (marque == null) {
        for (final pattern in brandPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            marque = match.group(1)?.trim() ?? '';
            break;
          }
        }
      }

      // Catégorie (mots-clés)
      final categoryKeywords = {
        'électronique': [
          'smartphone',
          'téléphone',
          'ordinateur',
          'laptop',
          'tablette'
        ],
        'vêtements': ['chemise', 'pantalon', 'robe', 'chaussures', 'mode'],
        'maison': ['meuble', 'décoration', 'cuisine', 'salon', 'chambre'],
        'sport': ['football', 'basket', 'running', 'fitness', 'sport'],
      };

      for (final entry in categoryKeywords.entries) {
        if (entry.value.any((keyword) => lowerLine.contains(keyword))) {
          categoryHints.add(entry.key);
        }
      }
    }

    // Désignation (première ligne significative)
    if (allLines.isNotEmpty) {
      for (final line in allLines) {
        if (line.length > 5 &&
            !pricePattern.hasMatch(line) &&
            !refPattern.hasMatch(line) &&
            !line.toLowerCase().contains('marque')) {
          designation = line;
          break;
        }
      }
    }

    // Description (concaténation des lignes descriptives)
    final descriptionLines = allLines
        .where((line) =>
            line.length > 20 &&
            !pricePattern.hasMatch(line) &&
            !refPattern.hasMatch(line))
        .take(3)
        .toList();

    description =
        descriptionLines.isNotEmpty ? descriptionLines.join(' ') : null;

    // Calcul de confiance
    final confidence = _calculateConfidence(
      hasPrice: prix != null,
      hasReference: reference != null,
      hasBrand: marque != null,
      hasDesignation: designation != null,
      totalLines: allLines.length,
    );

    return {
      'designation': designation,
      'marque': marque,
      'prix': prix,
      'reference': reference,
      'description': description,
      'categoryHints': categoryHints.distinct,
      'rawText': allLines.join('\n'),
      'blocks': allBlocks,
      'confidence': confidence,
    };
  }

  /// Calcul du score de confiance (0.0 - 1.0)
  double _calculateConfidence({
    required bool hasPrice,
    required bool hasReference,
    required bool hasBrand,
    required bool hasDesignation,
    required int totalLines,
  }) {
    double score = 0.0;

    if (hasPrice) score += 0.25;
    if (hasReference) score += 0.25;
    if (hasBrand) score += 0.2;
    if (hasDesignation) score += 0.2;
    if (totalLines > 3) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Recherche de produits similaires basée sur l'OCR
  Future<List<String>> findSimilarProducts({
    required String extractedText,
    required List<dynamic> products,
    int maxResults = 5,
  }) async {
    final extractedWords = extractedText
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .toSet();

    final scoredProducts = <({dynamic product, double score})>[];

    for (final product in products) {
      double score = 0.0;
      final productText = [
        product.designation ?? '',
        product.marque ?? '',
        product.reference ?? '',
      ].join(' ').toLowerCase();

      for (final word in extractedWords) {
        if (productText.contains(word)) {
          score += 1.0;
        }
      }

      if (score > 0) {
        scoredProducts.add((product: product, score: score));
      }
    }

    scoredProducts.sort((a, b) => b.score.compareTo(a.score));

    return scoredProducts
        .take(maxResults)
        .map((item) => item.product.id.toString())
        .toList();
  }

  void dispose() {
    for (final recognizer in _recognizerCache.values) {
      recognizer.close();
    }
    _recognizerCache.clear();
  }
}

extension<T> on List<T> {
  List<T> get distinct => toSet().toList();
}
