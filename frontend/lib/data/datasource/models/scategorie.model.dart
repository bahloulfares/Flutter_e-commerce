import 'package:atelier7/data/datasource/models/categories.model.dart';

class Scategorie {
  String? id;
  String? nomscategorieID;
  String? imagescategorie;
  Categorie? categorieID;

  Scategorie({this.id, this.nomscategorieID, this.imagescategorie, this.categorieID});

  Scategorie.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    nomscategorieID = json['nomscategorieID'];
    imagescategorie = json['imagescategorie'];
    categorieID = json['categorieID'] != null 
        ? Categorie.fromJson(json['categorieID']) 
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['nomscategorieID'] = nomscategorieID;
    data['imagescategorie'] = imagescategorie;
    if (categorieID != null) {
      data['categorieID'] = categorieID!.toJson();
    }
    return data;
  }
  
}
