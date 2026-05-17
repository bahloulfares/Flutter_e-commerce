import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final scannedRef = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScanScreen()));

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
          content: Text('${'gallery_scan_error'.tr}: $e'),
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
              title: Text('scan_with_camera'.tr),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('scan_from_gallery'.tr),
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

  Future<void> _handleScannedReference(
    String? scannedRef, {
    required String source,
  }) async {
    if (!mounted || scannedRef == null || scannedRef.trim().isEmpty) return;

    final cleanedRef = scannedRef.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'article_reference_detected'.tr
              .replaceAll('{source}', source)
              .replaceAll('{ref}', cleanedRef),
        ),
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
        title: Text('article_not_found'.tr),
        content: Text(
          'no_article_with_reference'.tr.replaceAll('{ref}', cleanedRef),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('annuler'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('create'.tr),
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
        title: Text('delete_article_question'.tr),
        content: Text('delete_named_item'.tr.replaceAll('{name}', name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('annuler'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _controller.deleteArticle(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'article_deleted_success'.tr : 'delete_error'.tr,
                    ),
                    backgroundColor: ok
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('delete'.tr),
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
        title: Text(
          'manage_articles'.tr,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'scan_reference'.tr,
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
        label: Text(
          'ajouter'.tr,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'search_article'.tr,
                hintStyle: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                  .where(
                    (a) =>
                        _search.isEmpty ||
                        (a.designation.toLowerCase().contains(_search)) ||
                        (a.marque?.toLowerCase().contains(_search) ?? false),
                  )
                  .toList();

              if (articles.isEmpty) {
                return Center(
                  child: Text(
                    'no_article_found'.tr,
                    style: GoogleFonts.poppins(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: articles.length,
                itemBuilder: (ctx, i) {
                  final art = articles[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.outline
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: art.imageart != null && art.imageart!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                art.imageart!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 56,
                                  height: 56,
                                  color: colorScheme.surfaceContainer,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 24,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory_2, color: colorScheme.onSurfaceVariant),
                            ),
                      title: Text(
                        art.designation,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (art.marque != null)
                              Text(
                                '${'marque'.tr}: ${art.marque}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '${art.prix} DT',
                                  style: GoogleFonts.poppins(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (art.qtestock ?? 0) > 0
                                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                        : colorScheme.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${'stock'.tr}: ${art.qtestock ?? 0}',
                                    style: GoogleFonts.poppins(
                                      color: (art.qtestock ?? 0) > 0
                                          ? const Color(0xFF10B981)
                                          : colorScheme.error,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => Navigator.of(context)
                                .pushNamed('/admin/editArticle', arguments: art)
                                .then((_) => _controller.fetchAllArticles()),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.delete_outline, color: colorScheme.error),
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
