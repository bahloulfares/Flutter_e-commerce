import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text('delete_subcategory_question'.tr),
        content: Text('delete_named_item'.tr.replaceAll('{name}', name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('annuler'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _controller.deleteScategorie(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'deleted_success'.tr : 'delete_error'.tr,
                    ),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'subcategories'.tr,
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
        label: Text(
          'ajouter'.tr,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.scategoriesList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'no_subcategory'.tr,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
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
                    : CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.category, color: colorScheme.onPrimaryContainer),
                      ),
                title: Text(
                  scat.nomscategorie ?? 'without_name'.tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: scat.categorie != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${'categories'.tr}: ${scat.categorie!.nomcategorie ?? ''}',
                          style: GoogleFonts.poppins(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : null,
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => Navigator.of(context)
                          .pushNamed('/admin/editScategorie', arguments: scat)
                          .then((_) {
                            _controller.fetchAllScategories();
                          }),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
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
