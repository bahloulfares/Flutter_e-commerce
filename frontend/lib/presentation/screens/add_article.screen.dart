import 'dart:developer' as developer;
import 'dart:io';

import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';
import 'package:atelier7/presentation/screens/scan_screen.dart';
import 'package:atelier7/utils/barcode_scanner_service.dart';
import 'package:atelier7/utils/ocr_service.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class AddArticleScreen extends StatefulWidget {
  final String? initialReference;

  const AddArticleScreen({super.key, this.initialReference});

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ArticleController _articleController = Get.find<ArticleController>();
  final ScategorieController _scatController = Get.find<ScategorieController>();
  final ImagePicker _imagePicker = ImagePicker();
  final BarcodeScannerService _barcodeScannerService = BarcodeScannerService();
  final OcrService _ocrService = OcrService();
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dymt4nyul',
    'koyuqu3d',
    cache: false,
  );

  final _designationCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _qtestockCtrl = TextEditingController();
  final _marqueCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  int? _selectedScategorieId;
  String? _selectedImagePath;
  bool _isUploadingImage = false;
  bool _isScanningReference = false;

  String _normalizeReference(String value) {
    return value.trim().replaceAll(' ', '');
  }

  bool _referenceExists(String value) {
    final normalized = _normalizeReference(value).toLowerCase();
    if (normalized.isEmpty) return false;
    return _articleController.articlesList.any(
      (article) =>
          _normalizeReference(article.reference ?? '').toLowerCase() ==
          normalized,
    );
  }

  void _applyScannedReference(String scannedValue, String sourceLabel) {
    final normalized = _normalizeReference(scannedValue);
    if (normalized.isEmpty) return;
    setState(() {
      _referenceCtrl.text = normalized;
    });

    final duplicate = _referenceExists(normalized);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          duplicate
              ? 'article_reference_duplicate'.tr
                    .replaceAll('{source}', sourceLabel)
                    .replaceAll('{ref}', normalized)
              : 'article_reference_detected'.tr
                    .replaceAll('{source}', sourceLabel)
                    .replaceAll('{ref}', normalized),
        ),
        backgroundColor: duplicate
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final initialRef = widget.initialReference;
    if (initialRef != null && initialRef.trim().isNotEmpty) {
      _referenceCtrl.text = _normalizeReference(initialRef);
    }
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
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _runOcrOnImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final result = await _ocrService.extractInfoFromImage(file);
      setState(() {
        if (result['designation']?.isNotEmpty == true) {
          _designationCtrl.text = result['designation']!;
        }
        if (result['marque']?.isNotEmpty == true) {
          _marqueCtrl.text = result['marque']!;
        }
        if (result['prix']?.isNotEmpty == true) {
          _prixCtrl.text = result['prix']!;
        }
        if (result['reference']?.isNotEmpty == true) {
          _referenceCtrl.text = result['reference']!;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ocr_text_extracted'.tr),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'ocr_error'.tr}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final reference = _normalizeReference(_referenceCtrl.text);
    _referenceCtrl.text = reference;
    if (reference.isNotEmpty && _referenceExists(reference)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('article_reference_exists'.tr),
          backgroundColor: Theme.of(context).colorScheme.secondary,
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

    final ok = await _articleController.createArticle(data);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'article_created_success'.tr
              : _articleController.errorMessage.value.isNotEmpty
              ? _articleController.errorMessage.value
              : 'article_create_error'.tr,
        ),
        backgroundColor: ok
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _pickExistingImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _selectedImagePath = picked.path;
      _isUploadingImage = true;
    });

    await _runOcrOnImage(picked.path);

    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          picked.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      setState(() {
        _imageCtrl.text = response.secureUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('image_uploaded_success'.tr),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
      developer.log(
        'Cloudinary URL: ${response.secureUrl}',
        name: 'AddArticleScreen',
      );
    } on CloudinaryException catch (error) {
      developer.log(
        'Cloudinary error: ${error.message}',
        name: 'AddArticleScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'image_upload_error'.tr}: ${error.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'image_upload_error'.tr}: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _scanReferenceFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isScanningReference = true);
    try {
      final scannedValue = await _barcodeScannerService.scanFromFilePath(
        picked.path,
      );
      if (scannedValue != null && mounted) {
        _applyScannedReference(scannedValue, 'galerie');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('barcode_no_valid_result'.tr),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'mlkit_scan_error'.tr}: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanningReference = false);
    }
  }

  Future<void> _scanReferenceLive() async {
    setState(() => _isScanningReference = true);
    try {
      final result = await Navigator.of(
        context,
      ).push<String>(MaterialPageRoute(builder: (_) => const ScanScreen()));
      if (!mounted) return;
      if (result != null && result.trim().isNotEmpty) {
        _applyScannedReference(result, 'caméra');
      }
    } finally {
      if (mounted) setState(() => _isScanningReference = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('add_article_title'.tr),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(
                _designationCtrl,
                'designation_required'.tr,
                Icons.label,
                required: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      _prixCtrl,
                      'price_required'.tr,
                      Icons.euro,
                      keyboard: TextInputType.number,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      _qtestockCtrl,
                      'stock_required'.tr,
                      Icons.inventory,
                      keyboard: TextInputType.number,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField(_marqueCtrl, 'brand'.tr, Icons.branding_watermark),
              const SizedBox(height: 12),
              _buildField(_referenceCtrl, 'reference'.tr, Icons.qr_code),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanningReference
                          ? null
                          : _scanReferenceLive,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _isScanningReference
                            ? 'scan_in_progress'.tr
                            : 'scan_camera'.tr,
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
                      label: Text('scan_gallery'.tr),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'barcode_formats_hint'.tr,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(_imageCtrl, 'image_url'.tr, Icons.image),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickExistingImage,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _isUploadingImage
                        ? 'upload_in_progress'.tr
                        : 'choose_existing_file_ocr'.tr,
                  ),
                ),
              ),
              if (_selectedImagePath != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${'file'.tr}: ${p.basename(_selectedImagePath!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
              if (_imageCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'cloudinary_url_ready'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Obx(() {
                final scats = _scatController.scategoriesList;
                return DropdownButtonFormField<int>(
                  initialValue: _selectedScategorieId,
                  decoration: InputDecoration(
                    labelText: 'subcategory'.tr,
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text('none_option'.tr),
                    ),
                    ...scats.map(
                      (s) => DropdownMenuItem<int>(
                        value: int.tryParse(s.id ?? ''),
                        child: Text(s.nomscategorie ?? 'without_name'.tr),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedScategorieId = v),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: _articleController.isLoading.value
                        ? null
                        : _submit,
                    icon: _articleController.isLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text('enregistrer'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
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
          ? (v) => (v == null || v.trim().isEmpty) ? 'required_field'.tr : null
          : null,
    );
  }
}
