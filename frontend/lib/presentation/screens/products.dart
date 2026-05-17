import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';
import 'package:atelier7/presentation/controllers/language.controller.dart';
import 'package:atelier7/presentation/controllers/translation_provider.dart';
import 'package:atelier7/presentation/widgets/mydrawer.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

String tr(String key) {
  final translationProvider = Get.isRegistered<TranslationProvider>()
      ? Get.find<TranslationProvider>()
      : null;
  return translationProvider?.getTranslation(key) ?? key.tr;
}

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  late final ArticleController _articleController;
  late final AuthController _authController;
  late final CategorieController _categorieController;

  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _articleController = Get.find<ArticleController>();
    _authController = Get.find<AuthController>();
    _categorieController = Get.find<CategorieController>();
    // Defer fetch to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _articleController.fetchAllArticles();
      _categorieController.fetchAllCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<LanguageController>(
        id: 'language',
        builder: (_) => Scaffold(
              drawer: const MyDrawer(),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(context, '/chatbot'),
                icon: const Icon(Icons.smart_toy),
                label: Text(tr('Assistant')),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              appBar: AppBar(
                elevation: 0,
                backgroundColor: colorScheme.primary,
                title: Text(
                  tr('boutique'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                centerTitle: false,
                iconTheme: IconThemeData(color: colorScheme.onPrimary),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.document_scanner_outlined, size: 26),
                    tooltip: tr('Scanner un produit'),
                    color: colorScheme.onPrimary,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/scanFusion'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: PersistentShoppingCart().showCartItemCountWidget(
                        cartItemCountWidgetBuilder: (int itemCount) => Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined,
                                  size: 28),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/cartView'),
                              color: colorScheme.onPrimary,
                            ),
                            if (itemCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    itemCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: colorScheme.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('bienvenue'),
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Obx(() => Text(
                                _authController.userName.value.isNotEmpty
                                    ? _authController.userName.value
                                    : tr('client'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                          const SizedBox(height: 12),
                          // Search Bar
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: tr('rechercher'),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Category Filter
                          Obx(() {
                            if (_categorieController.categoriesList.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  FilterChip(
                                    label: Text(tr('tout')),
                                    selected: _selectedCategoryId == null,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategoryId = null;
                                      });
                                    },
                                    selectedColor: colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: _selectedCategoryId == null
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ..._categorieController.categoriesList
                                      .map((cat) {
                                    final isSelected =
                                        _selectedCategoryId == cat.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(cat.nomcategorie),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedCategoryId =
                                                selected ? cat.id : null;
                                          });
                                        },
                                        selectedColor: colorScheme.primary,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),

                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        // Show loading indicator while fetching
                        if (_articleController.isLoading.value) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          );
                        }

                        // Show error message if exists
                        if (_articleController.errorMessage.value.isNotEmpty) {
                          return SingleChildScrollView(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 32.0, horizontal: 16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      _articleController.errorMessage.value,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.red),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _articleController.fetchAllArticles(),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Réessayer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Show empty state if no products
                        if (_articleController.articlesList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(tr('aucun_produit'),
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _articleController.fetchAllArticles(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Réessayer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Filter articles based on search query and category
                        final filteredArticles =
                            _articleController.articlesList.where((article) {
                          // Category filter - only if categorieId is available from API
                          if (_selectedCategoryId != null &&
                              article.categorieId != null) {
                            if (article.categorieId !=
                                int.tryParse(_selectedCategoryId!)) {
                              return false;
                            }
                          }

                          // Search filter - search in designation, marque, and reference
                          if (_searchQuery.isEmpty) return true;

                          final designation = article.designation.toLowerCase();
                          final marque = (article.marque ?? '').toLowerCase();
                          final reference =
                              (article.reference ?? '').toLowerCase();
                          final searchTerm = _searchQuery.toLowerCase();

                          // Return true if any field contains the search term
                          final matches = designation.contains(searchTerm) ||
                              marque.contains(searchTerm) ||
                              reference.contains(searchTerm);

                          return matches;
                        }).toList();

                        // Show empty state if no filtered products
                        if (filteredArticles.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Aucun produit trouvé pour "$_searchQuery"'
                                      : 'Aucun produit dans cette catégorie',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedCategoryId = null;
                                    });
                                  },
                                  child:
                                      const Text('Réinitialiser les filtres'),
                                ),
                              ],
                            ),
                          );
                        }

                        // Show products grid
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index];
                            return _ProductCard(
                                article: article, context: context);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ));
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic article;
  final BuildContext context;

  const _ProductCard({required this.article, required this.context});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool inStock = (article.qtestock ?? 0) > 0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/details', arguments: article),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? colorScheme.outline : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Zone image avec badge stock ─────────────────────
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15)),
                    child: Container(
                      width: double.infinity,
                      color: colorScheme.surfaceContainerHighest,
                      child: Image.network(
                        article.imageart ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Badge stock
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: inStock
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        inStock ? '${article.qtestock}' : '—',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Infos produit ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.designation ?? 'Produit',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${article.prix?.toStringAsFixed(2) ?? '0.00'} TND',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  // ── Bouton panier ────────────────────────────
                  PersistentShoppingCart().showAndUpdateCartItemWidget(
                    inCartWidget: _CartActionBtn(
                      label: tr('retirer'),
                      icon: Icons.check_rounded,
                      isInCart: true,
                      primaryColor: colorScheme.primary,
                    ),
                    notInCartWidget: _CartActionBtn(
                      label: tr('ajouter'),
                      icon: Icons.add_shopping_cart_rounded,
                      isInCart: false,
                      primaryColor: colorScheme.primary,
                    ),
                    product: PersistentShoppingCartItem(
                      productId: article.id,
                      productName: article.designation ?? 'Produit',
                      unitPrice: article.prix?.toDouble() ?? 0.0,
                      productImages: [article.imageart ?? ''],
                      quantity: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouton panier réutilisable ────────────────────────────────────────
class _CartActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isInCart;
  final Color primaryColor;

  const _CartActionBtn({
    required this.label,
    required this.icon,
    required this.isInCart,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: isInCart
            ? const Color(0xFFEF4444).withValues(alpha: 0.08)
            : primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: isInCart
            ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 13,
            color: isInCart ? const Color(0xFFEF4444) : Colors.white,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isInCart ? const Color(0xFFEF4444) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


