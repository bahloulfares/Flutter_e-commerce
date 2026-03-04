class Categorie {
 String? id;
 String? nomcategorie;
 String? imagecategorie;

  Categorie({this.id, this.nomcategorie, this.imagecategorie});

  Categorie.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    nomcategorie = json['nomcategorie'];
    imagecategorie = json['imagecategorie'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['nomcategorie'] = nomcategorie;
    data['imagecategorie'] = imagecategorie;
    return data;
  }
}
