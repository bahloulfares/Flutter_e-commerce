import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/scategorie.controller.dart';

class AdminScategoriesScreen extends StatefulWidget {
  const AdminScategoriesScreen({super.key});

  @override
  State<AdminScategoriesScreen> createState() => _AdminScategoriesScreenState();
}

class _AdminScategoriesScreenState extends State<AdminScategoriesScreen> {
  final ScategorieController _controller = Get.find<ScategorieController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAllScategories();
    });
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la sous-catégorie ?'),
        content: Text('Supprimer "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _controller.deleteScategorie(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Supprimé avec succès' : 'Erreur suppression',
                    ),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
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
        title: const Text('Sous-catégories'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.fetchAllScategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed('/admin/addScategorie').then((_) {
              _controller.fetchAllScategories();
            }),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.scategoriesList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Aucune sous-catégorie',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _controller.scategoriesList.length,
          itemBuilder: (ctx, i) {
            final scat = _controller.scategoriesList[i];
            final id = int.tryParse(scat.id ?? '') ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: scat.imagescat != null && scat.imagescat!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          scat.imagescat!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      )
                    : const CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Icon(Icons.category, color: Colors.white),
                      ),
                title: Text(
                  scat.nomscategorie ?? 'Sans nom',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: scat.categorie != null
                    ? Text(
                        'Catégorie: ${scat.categorie!.nomcategorie ?? ''}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      )
                    : null,
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => Navigator.of(context)
                          .pushNamed('/admin/editScategorie', arguments: scat)
                          .then((_) {
                            _controller.fetchAllScategories();
                          }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _confirmDelete(id, scat.nomscategorie ?? ''),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
