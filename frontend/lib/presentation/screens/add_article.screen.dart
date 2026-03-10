import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';
import 'package:atelier7/presentation/screens/scan_screen.dart';
import 'package:atelier7/utils/barcode_scanner_service.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class AddArticleScreen extends StatefulWidget {
  const AddArticleScreen({super.key});

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ArticleController _articleController = Get.find<ArticleController>();
  final ScategorieController _scatController = Get.find<ScategorieController>();
  final ImagePicker _imagePicker = ImagePicker();
  final BarcodeScannerService _barcodeScannerService = BarcodeScannerService();
  final CloudinaryPublic _cloudinary =
      CloudinaryPublic('dymt4nyul', 'koyuqu3d', cache: false);

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

  @override
  void initState() {
    super.initState();
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

    final reference = _referenceCtrl.text.trim();
    if (reference.isNotEmpty) {
      final hasDuplicate = _articleController.articlesList.any((article) =>
          (article.reference ?? '').trim().toLowerCase() ==
          reference.toLowerCase());

      if (hasDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cette référence existe déjà.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Article créé avec succès !'
            : _articleController.errorMessage.value.isNotEmpty
                ? _articleController.errorMessage.value
                : 'Erreur création'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) Navigator.pop(context);
    }
  }

  Future<void> _pickExistingImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _selectedImagePath = picked.path;
      _isUploadingImage = true;
    });

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
          const SnackBar(
            content: Text('Image uploadée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      developer.log('Cloudinary URL: ${response.secureUrl}',
          name: 'AddArticleScreen');
    } on CloudinaryException catch (error) {
      developer.log('Cloudinary error: ${error.message}',
          name: 'AddArticleScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload image: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload image: $error'),
            backgroundColor: Colors.red,
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

    setState(() {
      _isScanningReference = true;
    });
    try {
      final scannedValue =
          await _barcodeScannerService.scanFromFilePath(picked.path);

      if (scannedValue != null) {
        setState(() {
          _referenceCtrl.text = scannedValue;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Référence détectée avec ML Kit (galerie)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Aucun code-barres valide détecté (formats autorisés: EAN/UPC/Code128/Code39/QR).'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur scan ML Kit: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanningReference = false;
        });
      }
    }
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
        setState(() {
          _referenceCtrl.text = result.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Référence détectée avec ML Kit (caméra)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanningReference = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un article'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
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
                          _isScanningReference ? 'Scan...' : 'Scanner caméra'),
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
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Formats ML Kit autorisés: EAN-13, EAN-8, UPC-A, UPC-E, Code128, Code39, QR',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(_imageCtrl, 'URL Image', Icons.image),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickExistingImage,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_isUploadingImage
                      ? 'Upload en cours...'
                      : 'Choisir un fichier existant'),
                ),
              ),
              if (_selectedImagePath != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fichier: ${p.basename(_selectedImagePath!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
              if (_imageCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'URL Cloudinary prête',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Sous-catégorie dropdown
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
                  onChanged: (v) {
                    setState(() => _selectedScategorieId = v);
                  },
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
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
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
