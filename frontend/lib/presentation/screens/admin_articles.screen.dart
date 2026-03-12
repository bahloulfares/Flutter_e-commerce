import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/domain/entities/article.entity.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/screens/scan_screen.dart';
import 'package:atelier7/utils/barcode_scanner_service.dart';
import 'package:image_picker/image_picker.dart';

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  State<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen> {
  final ArticleController _controller = Get.find<ArticleController>();
  final BarcodeScannerService _barcodeScannerService = BarcodeScannerService();
  final ImagePicker _imagePicker = ImagePicker();
  String _search = '';

  String _normalizeReference(String value) {
    return value.trim().replaceAll(' ', '').toLowerCase();
  }

  ArticleEntity? _findByReference(String scannedRef) {
    final normalized = _normalizeReference(scannedRef);
    for (final article in _controller.articlesList) {
      if (_normalizeReference(article.reference ?? '') == normalized) {
        return article;
      }
    }
    return null;
  }

  Future<void> _scanAndFindArticle() async {
    final scannedRef = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );

    await _handleScannedReference(scannedRef, source: 'caméra');
  }

  Future<void> _scanAndFindArticleFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    String? scannedRef;
    try {
      scannedRef = await _barcodeScannerService.scanFromFilePath(picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur scan galerie: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await _handleScannedReference(scannedRef, source: 'galerie');
  }

  Future<void> _showScanOptionsSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Scanner avec la caméra'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Scanner depuis la galerie'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (selected == 'camera') {
      await _scanAndFindArticle();
    } else if (selected == 'gallery') {
      await _scanAndFindArticleFromGallery();
    }
  }

  Future<void> _handleScannedReference(String? scannedRef,
      {required String source}) async {
    if (!mounted || scannedRef == null || scannedRef.trim().isEmpty) return;

    final cleanedRef = scannedRef.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Référence détectée ($source): $cleanedRef'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );

    final article = _findByReference(cleanedRef);

    if (article != null) {
      if (!mounted) return;
      await Navigator.of(context)
          .pushNamed('/admin/editArticle', arguments: article)
          .then((_) => _controller.fetchAllArticles());
      return;
    }

    if (!mounted) return;
    final create = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Article introuvable'),
        content: Text(
          'Aucun article avec la référence "$cleanedRef".\nCréer un nouvel article prérempli ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (create == true && mounted) {
      await Navigator.of(context)
          .pushNamed('/admin/addArticle', arguments: cleanedRef)
          .then((_) => _controller.fetchAllArticles());
    }
  }

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
                  backgroundColor: ok
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.error,
                ));
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des articles'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner une référence',
            onPressed: _showScanOptionsSheet,
          ),
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
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
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
                          Wrap(
                            spacing: 10,
                            runSpacing: 2,
                            children: [
                              Text('${art.prix} DT',
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold)),
                              Text('Stock: ${art.qtestock ?? 0}',
                                  style: TextStyle(
                                      color: (art.qtestock ?? 0) > 0
                                          ? colorScheme.tertiary
                                          : colorScheme.error,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => Navigator.of(context)
                                .pushNamed('/admin/editArticle', arguments: art)
                                .then((_) => _controller.fetchAllArticles()),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.delete, color: colorScheme.error),
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
