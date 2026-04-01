import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:atelier7/utils/barcode_scanner_service.dart';
import 'package:atelier7/utils/ocr_service.dart';
import 'package:atelier7/data/datasource/services/article_service.dart';
import 'package:atelier7/data/datasource/models/article.model.dart';

enum _ScanState { idle, scanning, barcodeFound, ocrResults, notFound, error }

class ScanFusionScreen extends StatefulWidget {
  const ScanFusionScreen({super.key});

  @override
  State<ScanFusionScreen> createState() => _ScanFusionScreenState();
}

class _ScanFusionScreenState extends State<ScanFusionScreen> {
  final _barcodeService = BarcodeScannerService();
  final _ocrService = OcrService();
  final _articleService = ArticleService();
  final _picker = ImagePicker();

  _ScanState _state = _ScanState.idle;
  String _statusMessage = '';
  Article? _foundArticle;
  List<Article> _ocrResults = [];
  Map<String, String> _ocrData = {};
  File? _capturedImage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null) return;
    await _processImage(File(picked.path));
  }

  Future<void> _scanFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _processImage(File(picked.path));
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _state = _ScanState.scanning;
      _statusMessage = 'Analyse en cours...';
      _capturedImage = imageFile;
      _foundArticle = null;
      _ocrResults = [];
    });

    try {
      // Run barcode + OCR in parallel
      final results = await Future.wait([
        _barcodeService.scanFromFilePath(imageFile.path),
        _ocrService.extractInfoFromImage(imageFile),
      ]);

      final barcodeValue = results[0] as String?;
      final ocrData = results[1] as Map<String, String>;
      _ocrData = ocrData;

      // --- Strategy 1: barcode found → search by reference ---
      if (barcodeValue != null && barcodeValue.isNotEmpty) {
        setState(() => _statusMessage = 'Code-barres: $barcodeValue\nRecherche produit...');
        final articleJson = await _articleService.searchByReference(barcodeValue);
        if (articleJson != null) {
          setState(() {
            _foundArticle = Article.fromJson(articleJson);
            _state = _ScanState.barcodeFound;
            _statusMessage = 'Produit trouvé via code-barres';
          });
          return;
        }
      }

      // --- Strategy 2: OCR reference → search by reference ---
      final ocrRef = ocrData['reference'] ?? '';
      if (ocrRef.isNotEmpty) {
        final articleJson = await _articleService.searchByReference(ocrRef);
        if (articleJson != null) {
          setState(() {
            _foundArticle = Article.fromJson(articleJson);
            _state = _ScanState.barcodeFound;
            _statusMessage = 'Produit trouvé via référence OCR';
          });
          return;
        }
      }

      // --- Strategy 3: OCR text search ---
      final searchTerm = ocrData['designation']?.isNotEmpty == true
          ? ocrData['designation']!
          : ocrData['marque'] ?? '';

      if (searchTerm.isNotEmpty) {
        setState(() => _statusMessage = 'Recherche par texte OCR: "$searchTerm"...');
        final list = await _articleService.searchByText(searchTerm);
        if (list.isNotEmpty) {
          setState(() {
            _ocrResults = list.map((j) => Article.fromJson(j as Map<String, dynamic>)).toList();
            _state = _ScanState.ocrResults;
            _statusMessage = '${_ocrResults.length} résultat(s) OCR trouvé(s)';
          });
          return;
        }
      }

      // Nothing found
      setState(() {
        _state = _ScanState.notFound;
        _statusMessage = barcodeValue != null
            ? 'Code-barres "$barcodeValue" non trouvé dans la base'
            : 'Aucun produit identifié';
      });
    } catch (e) {
      setState(() {
        _state = _ScanState.error;
        _statusMessage = 'Erreur: $e';
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.idle;
      _statusMessage = '';
      _foundArticle = null;
      _ocrResults = [];
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Produit'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (_state != _ScanState.idle)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Nouveau scan',
              onPressed: _reset,
            ),
        ],
      ),
      body: _state == _ScanState.scanning
          ? _buildScanning(colorScheme)
          : _state == _ScanState.barcodeFound
              ? _buildArticleFound(colorScheme)
              : _state == _ScanState.ocrResults
                  ? _buildOcrResults(colorScheme)
                  : _state == _ScanState.notFound || _state == _ScanState.error
                      ? _buildNotFound(colorScheme)
                      : _buildIdle(colorScheme),
    );
  }

  Widget _buildIdle(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner_outlined, size: 80, color: cs.primary),
            const SizedBox(height: 24),
            Text(
              'Scanner un produit',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Prenez une photo ou choisissez une image.\nLe scan détecte automatiquement le code-barres ou le texte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _scanFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Prendre une photo'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _scanFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choisir depuis la galerie'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanning(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_capturedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_capturedImage!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 16),
          Text(_statusMessage, textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildArticleFound(ColorScheme cs) {
    final a = _foundArticle!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                const SizedBox(width: 6),
                Text(_statusMessage,
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Product card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.imageart != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      a.imageart!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: cs.surfaceContainer,
                        child: Icon(Icons.image_not_supported, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.designation ?? 'Produit',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (a.reference != null) ...[
                        const SizedBox(height: 4),
                        Text('Réf: ${a.reference}',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                      ],
                      if (a.marque != null) ...[
                        const SizedBox(height: 2),
                        Text('Marque: ${a.marque}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '${a.prix?.toStringAsFixed(2) ?? '0.00'} TND',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold, color: cs.primary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            (a.qtestock ?? 0) > 0 ? Icons.check_circle : Icons.cancel,
                            color: (a.qtestock ?? 0) > 0 ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (a.qtestock ?? 0) > 0
                                ? 'En stock: ${a.qtestock}'
                                : 'Rupture de stock',
                            style: TextStyle(
                              color: (a.qtestock ?? 0) > 0 ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/details', arguments: a),
            icon: const Icon(Icons.info_outline),
            label: const Text('Voir les détails'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Nouveau scan'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrResults(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.text_fields, color: cs.onSecondaryContainer, size: 16),
                    const SizedBox(width: 6),
                    Text('Résultats OCR', style: TextStyle(color: cs.onSecondaryContainer)),
                  ],
                ),
              ),
              if (_ocrData['designation']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Texte détecté: "${_ocrData['designation']}"',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _ocrResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = _ocrResults[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: cs.surfaceContainerHighest,
                leading: a.imageart != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(a.imageart!, width: 56, height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.image_not_supported, color: cs.onSurfaceVariant)),
                      )
                    : Icon(Icons.inventory_2_outlined, color: cs.primary, size: 40),
                title: Text(a.designation ?? 'Produit',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${a.prix?.toStringAsFixed(2) ?? '0'} TND  •  ${a.marque ?? ''}'),
                trailing: Icon(Icons.chevron_right, color: cs.primary),
                onTap: () => Navigator.pushNamed(context, '/details', arguments: a),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Nouveau scan'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_capturedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_capturedImage!, height: 160, fit: BoxFit.cover),
              ),
            const SizedBox(height: 24),
            Icon(
              _state == _ScanState.error ? Icons.error_outline : Icons.search_off,
              size: 64,
              color: _state == _ScanState.error ? cs.error : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (_ocrData.isNotEmpty && _ocrData['rawText']?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Texte OCR détecté', style: TextStyle(fontSize: 13)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_ocrData['rawText'] ?? '',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            ),
          ],
        ),
      ),
    );
  }
}
