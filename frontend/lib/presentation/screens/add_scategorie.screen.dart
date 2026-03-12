import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';
import 'package:atelier7/utils/cloudinary_upload_helper.dart';

class AddScategorieScreen extends StatefulWidget {
  const AddScategorieScreen({super.key});

  @override
  State<AddScategorieScreen> createState() => _AddScategorieScreenState();
}

class _AddScategorieScreenState extends State<AddScategorieScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScategorieController _scatController = Get.find<ScategorieController>();
  final CategorieController _catController = Get.find<CategorieController>();
  final ImagePicker _imagePicker = ImagePicker();

  final _nomCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String? _selectedCategorieId;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _catController.fetchAllCategories();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(source: source);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (mounted) {
      setState(() {
        _selectedImageBytes = bytes;
        _isUploadingImage = true;
      });
    }

    try {
      final imageUrl = await CloudinaryUploadHelper.uploadImage(
        picked,
        bytes: bytes,
      );

      _imageCtrl.text = imageUrl;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploadée avec succès'),
            backgroundColor: Colors.green,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nomscategorie': _nomCtrl.text.trim(),
      'imagescat': _imageCtrl.text.trim(),
      if (_selectedCategorieId != null)
        'categorieId': int.tryParse(_selectedCategorieId!),
    };

    final ok = await _scatController.createScategorie(data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Sous-catégorie créée !' : 'Erreur création'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une sous-catégorie'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: InputDecoration(
                  labelText: 'URL Image',
                  prefixIcon: const Icon(Icons.image),
                  suffixIcon: _imageCtrl.text.trim().isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              _imageCtrl.clear();
                              _selectedImageBytes = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isUploadingImage
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choisir image'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isUploadingImage
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Caméra'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.25),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    if (_isUploadingImage)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      ),
                    SizedBox(
                      height: 140,
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : _imageCtrl.text.trim().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _imageCtrl.text.trim(),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text('Aucune image sélectionnée'),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final cats = _catController.categoriesList;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategorieId,
                  decoration: InputDecoration(
                    labelText: 'Catégorie parente *',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: cats
                      .map((c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.nomcategorie),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategorieId = v),
                  validator: (v) =>
                      v == null ? 'Sélectionner une catégorie' : null,
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton.icon(
                      onPressed:
                          _scatController.isLoading.value ? null : _submit,
                      icon: _scatController.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
