import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';
import 'package:atelier7/presentation/widgets/categorieslist.widget.dart';

class Categorieslist extends StatelessWidget {
  const Categorieslist({super.key});

  @override
  Widget build(BuildContext context) {
    var contoller = Get.find<CategorieController>();
    contoller.fetchAllCategories();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
      ),
      body: Obx(
        () => contoller.isLoading.value == true
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: contoller.categoriesList.length,
                itemBuilder: (context, index) {
                  final categories = contoller.categoriesList[index];
                  return Categorieslistwidget(
                    categories: categories,
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {    
          Navigator.of(context).pushNamed('/addcategories'); 
          },
  child: const Icon(Icons.add),
      ),
    );
  }
}
