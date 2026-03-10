import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atelier7/presentation/controllers/order.controller.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final OrderController _controller = Get.find<OrderController>();

  final List<String> _statuses = [
    'Not processed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  final Map<String, Color> _statusColors = {
    'Not processed': Colors.orange,
    'Processing': Colors.blue,
    'Shipped': Colors.purple,
    'Delivered': Colors.green,
    'Cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAllOrders();
    });
  }

  void _showStatusDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Commande #${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Changer le statut :'),
            const SizedBox(height: 12),
            ..._statuses.map((s) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: _statusColors[s] ?? Colors.grey,
                    radius: 8,
                  ),
                  title: Text(s),
                  selected: order['status'] == s,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await _controller.updateOrderStatus(
                        order['id'] as int, s);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            ok ? 'Statut mis à jour' : 'Erreur mise à jour'),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ));
                    }
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la commande ?'),
        content: Text('Commande #${order['id']} de ${order['client']}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.deleteOrder(order['id'] as int);
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
        title: const Text('Gestion des commandes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.fetchAllOrders,
          )
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.ordersList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Aucune commande', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _controller.ordersList.length,
          itemBuilder: (context, index) {
            final order = _controller.ordersList[index];
            final status = order['status'] as String? ?? 'Not processed';
            final statusColor = _statusColors[status] ?? Colors.grey;
            final lines = (order['lineOrder'] as List<dynamic>?) ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Text(
                    '#${order['id']}',
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
                title: Text(
                  order['client']?.toString() ?? 'Client inconnu',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_controller.getOrderTotal(order).toStringAsFixed(2)} DT',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showStatusDialog(order),
                      tooltip: 'Changer statut',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(order),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
                children: [
                  if (lines.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Articles :',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...lines.map((line) {
                            final article = line['article'];
                            return ListTile(
                              dense: true,
                              title: Text(
                                  article?['designation'] ?? 'Article inconnu'),
                              trailing: Text(
                                'x${line['quantity']}  —  ${line['totalPrice']} DT',
                                style: const TextStyle(color: Colors.indigo),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
