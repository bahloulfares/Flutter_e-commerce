import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/article.controller.dart';
import 'package:atelier7/presentation/widgets/articleslist.widget.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';

class ArticlesListScreen extends StatefulWidget {
  const ArticlesListScreen({super.key});

  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  late ArticleController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ArticleController>();
    // Appeler une seule fois au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAllArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    var controller = Get.find<ArticleController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontSize: 15),
        ),
        centerTitle: true,
        actions: [
          PersistentShoppingCart().showCartItemCountWidget(
            cartItemCountWidgetBuilder: (itemCount) => IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/cartView');
              },
              icon: Badge(
                label: Text(itemCount.toString()),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
          const SizedBox(width: 20.0)
        ],
      ),
      body: Obx(
        () => controller.isLoading.value == true
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: ListView.builder(
                      itemCount: controller.articlesList.length,
                      itemBuilder: (context, index) {
                        final articles = controller.articlesList[index];
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: ArticlesListWidget(
                              articles: articles,
                            ));
                      }),
                ),
              ),
      ),
    );
  }
}
