class Article {
  String? id;
  String? reference;
  String? designation;
  num? prix;
  String? marque;
  int? qtestock;
  String? imageart;
  Map<String, dynamic>? scategorieID;

  Article(
      {this.id,
      this.reference,
      this.designation,
      this.prix,
      this.marque,
      this.qtestock,
      this.imageart,
      this.scategorieID});

  Article.fromJson(Map<String, dynamic> json) { 
    id = json['_id'];
    reference = json['reference'];
    designation = json['designation'];
    prix = json['prix'];
    marque = json['marque'];
    qtestock = json['qtestock'];
    imageart = json['imageart'];
    scategorieID = json['scategorieID'] ;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['reference'] = reference;
    data['designation'] = designation;
    data['prix'] = prix;
    data['marque'] = marque;
    data['qtestock'] = qtestock;
    data['imageart'] = imageart;
    data['scategorieID'] = scategorieID;
  return data;
  }
}
