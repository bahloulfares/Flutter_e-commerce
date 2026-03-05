import 'package:flutter/material.dart';
import 'package:atelier7/domain/entities/categorie.entity.dart';
import 'package:atelier7/presentation/widgets/editCategorieForm.widget.dart';

class Editcategorie extends StatelessWidget {
  final CategorieEntity categorie;
  const Editcategorie({super.key, required this.categorie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 15,
        backgroundColor: Colors.greenAccent,
        title: const Text("Edit Categories"),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: EditCategorieForm(categorie: categorie),
    );
  }
}
