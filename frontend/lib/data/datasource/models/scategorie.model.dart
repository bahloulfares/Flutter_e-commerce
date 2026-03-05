import 'package:atelier7/data/datasource/models/categories.model.dart';

class Scategorie {
  String? id;
  String? nomscategorie;
  String? imagescat;
  int? categorieId;
  Categorie? categorie;

  Scategorie({
    this.id,
    this.nomscategorie,
    this.imagescat,
    this.categorieId,
    this.categorie,
  });

  Scategorie.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString(); // Convert int to string
    nomscategorie = json['nomscategorie'];
    imagescat = json['imagescat'];
    categorieId = json['categorieId'];
    categorie = json['categorie'] != null
        ? Categorie.fromJson(json['categorie'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nomscategorie'] = nomscategorie;
    data['imagescat'] = imagescat;
    data['categorieId'] = categorieId;
    if (categorie != null) {
      data['categorie'] = categorie!.toJson();
    }
    return data;
  }
}
