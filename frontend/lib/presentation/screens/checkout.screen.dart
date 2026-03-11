import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_shopping_cart/persistent_shopping_cart.dart';
import 'package:atelier7/presentation/controllers/order.controller.dart';
import 'package:atelier7/presentation/controllers/user.controller.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill name from auth controller
    final authController = Get.find<AuthController>();
    _nameController.text = authController.userName.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Helper method to safely convert unitPrice (can be String or num) to double
  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final orderController = Get.find<OrderController>();

    // Get cart items using the cart data map
    final cartDataMap = PersistentShoppingCart().getCartData();
    final List cartItemsList = cartDataMap['cartItems'] ?? [];

    if (cartItemsList.isEmpty) {
      Get.snackbar(
        'Panier vide',
        'Ajoutez des articles avant de passer commande',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Transform cart items to order format
    final items = cartItemsList.map((item) {
      return {
        'articleId': item.productId,
        'quantity': item.quantity,
        'unitPrice': _toDouble(item.unitPrice), // Ensure unitPrice is a number
      };
    }).toList();

    final success = await orderController.placeOrder(
      clientName: _nameController.text.trim(),
      clientPhone: _phoneController.text.trim(),
      clientAddress: _addressController.text.trim(),
      cartItems: items,
    );

    if (success) {
      // Clear cart
      PersistentShoppingCart().clearCart();

      // Navigate to confirmation
      Get.offNamed('/orderConfirmation');
    } else {
      Get.snackbar(
        'Erreur',
        orderController.errorMessage.value.isNotEmpty
            ? orderController.errorMessage.value
            : 'Impossible de passer la commande',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderController = Get.find<OrderController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text(
          'Finaliser la commande',
          style: TextStyle(color: colorScheme.onPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cart Summary
            PersistentShoppingCart().showCartItems(
              cartItemsBuilder: (context, cartItems) {
                if (cartItems.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Votre panier est vide'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final data = cartItems[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              (data.productImages?.isNotEmpty ?? false)
                                  ? data.productImages!.first
                                  : 'https://via.placeholder.com/80',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 60,
                                height: 60,
                                color: colorScheme.surfaceContainer,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_toDouble(data.unitPrice).toStringAsFixed(2)} TND × ${data.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(_toDouble(data.unitPrice) * data.quantity).toStringAsFixed(2)} TND',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // Total Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PersistentShoppingCart().showTotalAmountWidget(
                cartTotalAmountWidgetBuilder: (totalAmount) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_toDouble(totalAmount).toStringAsFixed(2)} TND',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Customer Information Form
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations de livraison',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Téléphone *',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le téléphone est requis';
                        }
                        if (value.length < 8) {
                          return 'Numéro invalide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Adresse de livraison *',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'adresse est requise';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (optionnel)',
                        prefixIcon: const Icon(Icons.note_outlined),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Place Order Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() => SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                          orderController.isLoading.value ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: orderController.isLoading.value
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirmer la commande',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                    ),
                  )),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
