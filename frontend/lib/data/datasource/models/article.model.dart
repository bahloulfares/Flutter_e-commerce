import 'dart:developer' as developer;

class Article {
  String? id;
  String? reference;
  String? designation;
  num? prix;
  String? marque;
  int? qtestock;
  String? imageart;
  int? scategorieID; // Changed to int - it's the subcategory ID number

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
    try {
      id = json['id']?.toString(); // Convert int to string
      reference = json['reference'];
      designation = json['designation'];
      // Handle prix as both string and number
      if (json['prix'] is String) {
        prix = num.tryParse(json['prix']) ?? 0;
      } else {
        prix = json['prix'];
      }
      marque = json['marque'];
      qtestock = json['qtestock'];
      imageart = json['imageart'];
      scategorieID = json['scategorieId'] is int
          ? json['scategorieId']
          : int.tryParse(json['scategorieId']?.toString() ?? '');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Article.fromJson ERROR: $e\n📦 JSON: $json',
        name: 'ArticleModel',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
