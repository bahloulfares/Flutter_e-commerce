import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';
import 'package:atelier7/presentation/screens/scan_screen.dart';
import 'package:atelier7/utils/barcode_scanner_service.dart';
import 'package:image_picker/image_picker.dart';

class EditArticleScreen extends StatefulWidget {
  final ArticleEntity article;
  const EditArticleScreen({super.key, required this.article});

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ArticleController _articleController = Get.find<ArticleController>();
  final ScategorieController _scatController = Get.find<ScategorieController>();
  final BarcodeScannerService _barcodeScannerService = BarcodeScannerService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _designationCtrl;
  late TextEditingController _prixCtrl;
  late TextEditingController _qtestockCtrl;
  late TextEditingController _marqueCtrl;
  late TextEditingController _referenceCtrl;
  late TextEditingController _imageCtrl;
  int? _selectedScategorieId;
  bool _isScanningReference = false;

  String _normalizeReference(String value) {
    return value.trim().replaceAll(' ', '');
  }

  bool _referenceExistsForAnotherArticle(String value) {
    final normalized = _normalizeReference(value).toLowerCase();
    if (normalized.isEmpty) return false;

    return _articleController.articlesList.any((article) {
      final sameArticle = article.id == widget.article.id;
      if (sameArticle) return false;
      final articleRef =
          _normalizeReference(article.reference ?? '').toLowerCase();
      return articleRef == normalized;
    });
  }

  void _applyScannedReference(String scannedValue, String sourceLabel) {
    final normalized = _normalizeReference(scannedValue);
    if (normalized.isEmpty) return;

    setState(() {
      _referenceCtrl.text = normalized;
    });

    final duplicate = _referenceExistsForAnotherArticle(normalized);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          duplicate
              ? 'Référence déjà utilisée ($sourceLabel): $normalized'
              : 'Référence détectée ($sourceLabel): $normalized',
        ),
        backgroundColor: duplicate
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  Future<void> _scanReferenceLive() async {
    setState(() {
      _isScanningReference = true;
    });

    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );

      if (!mounted) return;

      if (result != null && result.trim().isNotEmpty) {
        _applyScannedReference(result, 'caméra');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanningReference = false;
        });
      }
    }
  }

  Future<void> _scanReferenceFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isScanningReference = true;
    });

    try {
      final scannedValue =
          await _barcodeScannerService.scanFromFilePath(picked.path);

      if (!mounted) return;

      if (scannedValue != null && scannedValue.trim().isNotEmpty) {
        _applyScannedReference(scannedValue, 'galerie');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Aucun code-barres valide détecté (EAN/UPC/Code128/Code39/QR).',
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur scan ML Kit: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanningReference = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final art = widget.article;
    _designationCtrl = TextEditingController(text: art.designation);
    _prixCtrl = TextEditingController(text: art.prix?.toString() ?? '');
    _qtestockCtrl = TextEditingController(text: art.qtestock?.toString() ?? '');
    _marqueCtrl = TextEditingController(text: art.marque ?? '');
    _referenceCtrl = TextEditingController(text: art.reference ?? '');
    _imageCtrl = TextEditingController(text: art.imageart ?? '');
    _selectedScategorieId = art.scategorieId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scatController.fetchAllScategories();
      _articleController.fetchAllArticles();
    });
  }

  @override
  void dispose() {
    _designationCtrl.dispose();
    _prixCtrl.dispose();
    _qtestockCtrl.dispose();
    _marqueCtrl.dispose();
    _referenceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final reference = _normalizeReference(_referenceCtrl.text);
    _referenceCtrl.text = reference;
    if (reference.isNotEmpty && _referenceExistsForAnotherArticle(reference)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette référence existe déjà pour un autre article.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final data = {
      'designation': _designationCtrl.text.trim(),
      'prix': double.tryParse(_prixCtrl.text.trim()) ?? 0,
      'qtestock': int.tryParse(_qtestockCtrl.text.trim()) ?? 0,
      'marque': _marqueCtrl.text.trim(),
      'reference': _referenceCtrl.text.trim(),
      'imageart': _imageCtrl.text.trim(),
      if (_selectedScategorieId != null) 'scategorieId': _selectedScategorieId,
    };

    final ok = await _articleController.updateArticle(widget.article.id, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Article modifié avec succès !'
            : _articleController.errorMessage.value.isNotEmpty
                ? _articleController.errorMessage.value
                : 'Erreur'),
        backgroundColor: ok
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error,
      ));
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'article'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_designationCtrl, 'Désignation *', Icons.label,
                  required: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildField(_prixCtrl, 'Prix (DT) *', Icons.euro,
                          keyboard: TextInputType.number, required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildField(
                          _qtestockCtrl, 'Stock *', Icons.inventory,
                          keyboard: TextInputType.number, required: true)),
                ],
              ),
              const SizedBox(height: 12),
              _buildField(_marqueCtrl, 'Marque', Icons.branding_watermark),
              const SizedBox(height: 12),
              _buildField(_referenceCtrl, 'Référence', Icons.qr_code),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isScanningReference ? null : _scanReferenceLive,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _isScanningReference ? 'Scan...' : 'Scanner caméra',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanningReference
                          ? null
                          : _scanReferenceFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Scanner galerie'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField(_imageCtrl, 'URL Image', Icons.image),
              const SizedBox(height: 12),
              Obx(() {
                final scats = _scatController.scategoriesList;
                return DropdownButtonFormField<int>(
                  initialValue: _selectedScategorieId,
                  decoration: InputDecoration(
                    labelText: 'Sous-catégorie',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                        value: null, child: Text('--- Aucune ---')),
                    ...scats.map((s) => DropdownMenuItem<int>(
                          value: int.tryParse(s.id ?? ''),
                          child: Text(s.nomscategorie ?? 'Sans nom'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedScategorieId = v),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton.icon(
                      onPressed:
                          _articleController.isLoading.value ? null : _submit,
                      icon: _articleController.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}
