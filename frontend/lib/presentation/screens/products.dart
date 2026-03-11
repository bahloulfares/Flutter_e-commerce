import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';
import 'package:atelier7/presentation/controllers/categorie.controller.dart';
import 'package:atelier7/presentation/widgets/mydrawer.dart';
import 'package:atelier7/utils/constants.dart';
import 'package:persistent_shopping_cart/model/cart_model.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

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

    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        title: Text(
          'Boutique',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: PersistentShoppingCart().showCartItemCountWidget(
                cartItemCountWidgetBuilder: (int itemCount) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, size: 28),
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
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            itemCount.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
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
                    'Bienvenue',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Obx(() => Text(
                        _authController.userName.value.isNotEmpty
                            ? _authController.userName.value
                            : 'Client',
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
                      hintText: 'Rechercher un produit...',
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
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                            label: const Text('Tout'),
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
                          ..._categorieController.categoriesList.map((cat) {
                            final isSelected = _selectedCategoryId == cat.id;
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
                          }).toList(),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  // Debug info
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.tertiary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔧 Debug: API = $baseUrl',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                        Obx(() => Text(
                              '📊 Articles chargés: ${_articleController.articlesList.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            )),
                      ],
                    ),
                  ),
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
                        Text('Aucun produit disponible',
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
                  final reference = (article.reference ?? '').toLowerCase();
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
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      ],
                    ),
                  );
                }

                // Show products grid
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = filteredArticles[index];
                    return _ProductCard(article: article, context: context);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic article;
  final BuildContext context;

  const _ProductCard({required this.article, required this.context});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/details', arguments: article),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    article.imageart ?? 'https://via.placeholder.com/200',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colorScheme.surfaceContainer,
                      child: Icon(
                        Icons.image_not_supported,
                        color: colorScheme.onSurfaceVariant,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.designation ?? 'Produit',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '${article.prix?.toStringAsFixed(2) ?? '0'} TND',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            'Stock: ${article.qtestock ?? 0}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: PersistentShoppingCart().showAndUpdateCartItemWidget(
                      inCartWidget: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.red,
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Retirer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      notInCartWidget: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF6C63FF),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Ajouter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      product: PersistentShoppingCartItem(
                        productId: article.id,
                        productName: article.designation ?? 'Produit',
                        unitPrice: article.prix?.toDouble() ?? 0.0,
                        productImages: [article.imageart ?? ''],
                        quantity: 1,
                      ),
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
