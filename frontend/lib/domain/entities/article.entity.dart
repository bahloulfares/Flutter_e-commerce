class ArticleEntity {
  final String id;
  final String designation;
  final num? prix;
  final int? qtestock;
  final String? imageart;
  final String? marque;
  final String? reference;
  final int? scategorieId;
  final int? categorieId;

  ArticleEntity({
    required this.id,
    required this.designation,
    required this.prix,
    required this.qtestock,
    required this.imageart,
    this.marque,
    this.reference,
    this.scategorieId,
    this.categorieId,
  });
}
