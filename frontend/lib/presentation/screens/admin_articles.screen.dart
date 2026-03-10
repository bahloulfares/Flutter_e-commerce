import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  State<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen> {
  final ArticleController _controller = Get.find<ArticleController>();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAllArticles();
    });
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'article ?'),
        content: Text('Supprimer "$name" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _controller.deleteArticle(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Article supprimé' : 'Erreur suppression'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des articles'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.fetchAllArticles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed('/admin/addArticle').then((_) {
          _controller.fetchAllArticles();
        }),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un article...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final articles = _controller.articlesList
                  .where((a) =>
                      _search.isEmpty ||
                      (a.designation.toLowerCase().contains(_search)) ||
                      (a.marque?.toLowerCase().contains(_search) ?? false))
                  .toList();

              if (articles.isEmpty) {
                return const Center(
                    child: Text('Aucun article trouvé',
                        style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: articles.length,
                itemBuilder: (ctx, i) {
                  final art = articles[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: art.imageart != null && art.imageart!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                art.imageart!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    size: 40),
                              ),
                            )
                          : const Icon(Icons.inventory_2, size: 40),
                      title: Text(art.designation,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (art.marque != null)
                            Text('Marque: ${art.marque}',
                                style: const TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              Text('${art.prix} DT',
                                  style: const TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 10),
                              Text('Stock: ${art.qtestock ?? 0}',
                                  style: TextStyle(
                                      color: (art.qtestock ?? 0) > 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => Navigator.of(context)
                                .pushNamed('/admin/editArticle', arguments: art)
                                .then((_) => _controller.fetchAllArticles()),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDelete(art.id, art.designation),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
