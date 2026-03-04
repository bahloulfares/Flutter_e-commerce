import 'dart:io';
import 'dart:developer' as developer;

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:atelier7/domain/entities/categorie.entity.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';

class EditCategorieForm extends StatefulWidget {
  final CategorieEntity
      categorie; // Paramètre pour passer la catégorie à modifier

  const EditCategorieForm({super.key, required this.categorie});

  @override
  State<EditCategorieForm> createState() => _EditCategorieFormState();
}

class _EditCategorieFormState extends State<EditCategorieForm> {
  final CategorieController _controller = Get.put(CategorieController(
    useCase: Get.find(),
  ));

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomcategorieController;

  @override
  void initState() {
    super.initState();
    _nomcategorieController = TextEditingController(
        text: widget.categorie.nomcategorie); // Remplir avec le nom actuel
    imagecloud = widget
        .categorie.imagecategorie; // Remplir avec l'URL de l'image actuelle
  }

  File? path;
  String imagecloud = "";

  final cloudinary = CloudinaryPublic('dymt4nyul', 'koyuqu3d', cache: false);

  ImagePicker picker = ImagePicker();

  void _pickcamera() async {
    XFile? image = await picker.pickImage(source: ImageSource.camera);
    path = File(image!.path);

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path,
            resourceType: CloudinaryResourceType.Image),
      );

      developer.log('Cloudinary URL: ${response.secureUrl}',
          name: 'EditCategorieForm');
      setState(() {
        imagecloud = response.secureUrl;
      });
    } on CloudinaryException catch (e) {
      developer.log('Cloudinary error: ${e.message}',
          name: 'EditCategorieForm');
      developer.log('Cloudinary request: ${e.request}',
          name: 'EditCategorieForm');
    }
  }

  void _pickgallery() async {
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    path = File(image!.path);

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path,
            resourceType: CloudinaryResourceType.Image),
      );

      developer.log('Cloudinary URL: ${response.secureUrl}',
          name: 'EditCategorieForm');
      setState(() {
        imagecloud = response.secureUrl;
      });
    } on CloudinaryException catch (e) {
      developer.log('Cloudinary error: ${e.message}',
          name: 'EditCategorieForm');
      developer.log('Cloudinary request: ${e.request}',
          name: 'EditCategorieForm');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _nomcategorieController,
            decoration: const InputDecoration(
                hintText: "Category name", labelText: "Name"),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter the name';
              }
              return null;
            },
          ),
          Container(
            height: 40.0,
          ),
          Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_album_rounded, color: Colors.pink),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                ),
                onPressed: () {
                  _pickgallery();
                },
                label: const Text(
                  "PICK FROM GALLERY",
                  style: TextStyle(
                      color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 40.0,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_sharp, color: Colors.purple),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent,
                ),
                onPressed: () {
                  _pickcamera();
                },
                label: const Text(
                  "PICK FROM CAMERA",
                  style: TextStyle(
                      color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 40.0,
              ),
              SizedBox(
                height: 250,
                width: 250,
                child: imagecloud != ""
                    ? Image.network(imagecloud)
                    : Container(
                        decoration: BoxDecoration(color: Colors.red[200]),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[800],
                        ),
                      ),
              ),
              Container(
                height: 20.0,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      try {
                        // Mise à jour de la catégorie
                        _controller.updateCategorie(
                          widget.categorie.id, // ID de la catégorie à modifier
                          _nomcategorieController.text,
                          imagecloud,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Category updated successfully')),
                        );
                        Navigator.of(context).pushNamed('/Categories');
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error updating category: $error')),
                        );
                      }
                    }
                  },
                  child: const Text("Update"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
