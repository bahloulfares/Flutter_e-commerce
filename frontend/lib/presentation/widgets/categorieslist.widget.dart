import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/categorie.entity.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';

class Categorieslistwidget extends StatelessWidget {
  final CategorieEntity categories;
  Categorieslistwidget({super.key, required this.categories});
//on a enlevé const pour Categorieslistwidget
// car : Can't define the 'const' constructor because the field 'controller' is initialized with a non-constant value.

  final controller = Get.find<CategorieController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: ListTile(
          leading: Image.network(
            categories.imagecategorie,
            width: 68,
            height: 68,
          ),
          title: Text(categories.nomcategorie),
          trailing: Wrap(
            children: <Widget>[
              IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.green,
                  ),
                  onPressed: () => {
                        Navigator.of(context)
                            .pushNamed("/editcategories", arguments: categories)
                      }),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () => controller.deleteCategorie(categories.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
