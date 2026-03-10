import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';

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

  late TextEditingController _designationCtrl;
  late TextEditingController _prixCtrl;
  late TextEditingController _qtestockCtrl;
  late TextEditingController _marqueCtrl;
  late TextEditingController _referenceCtrl;
  late TextEditingController _imageCtrl;
  int? _selectedScategorieId;

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
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'article'),
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
