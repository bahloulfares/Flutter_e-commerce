import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';

class AddScategorieScreen extends StatefulWidget {
  const AddScategorieScreen({super.key});

  @override
  State<AddScategorieScreen> createState() => _AddScategorieScreenState();
}

class _AddScategorieScreenState extends State<AddScategorieScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScategorieController _scatController = Get.find<ScategorieController>();
  final CategorieController _catController = Get.find<CategorieController>();

  final _nomCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String? _selectedCategorieId;

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
                      borderRadius: BorderRadius.circular(10)),
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final cats = _catController.categoriesList;
                return DropdownButtonFormField<String>(
                  value: _selectedCategorieId,
                  decoration: InputDecoration(
                    labelText: 'Catégorie parente *',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
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
}
