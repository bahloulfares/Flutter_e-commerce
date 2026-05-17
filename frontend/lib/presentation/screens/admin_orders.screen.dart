import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String _statusLabel(String status) {
    switch (status) {
      case 'Not processed':
        return 'order_status_not_processed'.tr;
      case 'Processing':
        return 'order_status_processing'.tr;
      case 'Shipped':
        return 'order_status_shipped'.tr;
      case 'Delivered':
        return 'order_status_delivered'.tr;
      case 'Cancelled':
        return 'order_status_cancelled'.tr;
      default:
        return status;
    }
  }

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
        title: Text('order_number'.tr.replaceAll('{id}', '${order['id']}')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('change_status'.tr),
            const SizedBox(height: 12),
            ..._statuses.map(
              (s) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: _statusColors[s] ?? Colors.grey,
                  radius: 8,
                ),
                title: Text(_statusLabel(s)),
                selected: order['status'] == s,
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _controller.updateOrderStatus(
                    order['id'] as int,
                    s,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'status_updated'.tr : 'status_update_error'.tr,
                        ),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('annuler'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_order_question'.tr),
        content: Text(
          'order_of_client'.tr
              .replaceAll('{id}', '${order['id']}')
              .replaceAll('{client}', '${order['client']}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('annuler'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.deleteOrder(order['id'] as int);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'manage_orders'.tr,
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
            onPressed: _controller.fetchAllOrders,
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.ordersList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'no_orders'.tr,
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
          itemCount: _controller.ordersList.length,
          itemBuilder: (context, index) {
            final order = _controller.ordersList[index];
            final status = order['status'] as String? ?? 'Not processed';
            final statusColor = _statusColors[status] ?? Colors.grey;
            final lines = (order['lineOrder'] as List<dynamic>?) ?? [];

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
              child: ExpansionTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Text(
                    '#${order['id']}',
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: Text(
                  order['client']?.toString() ?? 'unknown_client'.tr,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_controller.getOrderTotal(order).toStringAsFixed(2)} DT',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _showStatusDialog(order),
                      tooltip: 'change_status_tooltip'.tr,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: () => _confirmDelete(order),
                      tooltip: 'delete'.tr,
                    ),
                  ],
                ),
                children: [
                  if (lines.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'articles_label'.tr,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...lines.map((line) {
                            final article = line['article'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      article?['designation'] ?? 'unknown_article'.tr,
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    'x${line['quantity']}  —  ${_controller.getLineTotal(Map<String, dynamic>.from(line)).toStringAsFixed(2)} DT',
                                    style: GoogleFonts.poppins(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
