import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:atelier7/data/datasource/models/scategorie.model.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';
import 'package:atelier7/utils/cloudinary_upload_helper.dart';

class EditScategorieScreen extends StatefulWidget {
  final Scategorie scategorie;
  const EditScategorieScreen({super.key, required this.scategorie});

  @override
  State<EditScategorieScreen> createState() => _EditScategorieScreenState();
}

class _EditScategorieScreenState extends State<EditScategorieScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScategorieController _scatController = Get.find<ScategorieController>();
  final CategorieController _catController = Get.find<CategorieController>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nomCtrl;
  late TextEditingController _imageCtrl;
  String? _selectedCategorieId;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final scat = widget.scategorie;
    _nomCtrl = TextEditingController(text: scat.nomscategorie ?? '');
    _imageCtrl = TextEditingController(text: scat.imagescat ?? '');
    _selectedCategorieId = scat.categorieId?.toString();

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
          SnackBar(
            content: Text('image_uploaded_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'image_upload_error'.tr}: $error'),
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

    final id = int.tryParse(widget.scategorie.id ?? '') ?? 0;
    final data = {
      'nomscategorie': _nomCtrl.text.trim(),
      'imagescat': _imageCtrl.text.trim(),
      if (_selectedCategorieId != null)
        'categorieId': int.tryParse(_selectedCategorieId!),
    };

    final ok = await _scatController.updateScategorie(id, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'subcategory_updated_success'.tr
                : 'subcategory_update_error'.tr,
          ),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_subcategory_title'.tr),
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
                  labelText: 'name_required'.tr,
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'required_field'.tr
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: InputDecoration(
                  labelText: 'image_url'.tr,
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
                    label: Text('choose_image'.tr),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isUploadingImage
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text('camera'.tr),
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
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text('no_image_selected'.tr),
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
                    labelText: 'parent_category'.tr,
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: cats
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.nomcategorie),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategorieId = v),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed: _scatController.isLoading.value ? null : _submit,
                    icon: _scatController.isLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text('enregistrer'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
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
}
