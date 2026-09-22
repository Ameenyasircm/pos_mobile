import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/table_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/bill_model.dart';
import '../../data/services/bill_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/menu_provider.dart';
import '../admin/admin_billing_auth_dialog.dart';
import 'staff_create_order_screen.dart';

class TableSessionHubDialog extends StatefulWidget {
  final TableModel table;

  const TableSessionHubDialog({
    super.key,
    required this.table,
  });

  @override
  State<TableSessionHubDialog> createState() => _TableSessionHubDialogState();
}

class _TableSessionHubDialogState extends State<TableSessionHubDialog> {
  void _openAddItemModal(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddItemModalContent(
        order: order,
      ),
    );
  }

  void _handleCheckout(BuildContext context, List<OrderModel> activeOrders, double grandTotal) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    String? adminName;
    if (authProvider.isAdmin) {
      adminName = authProvider.currentAdmin?.name ?? 'Admin';
    } else {
      // Prompt for Admin Authorization
      adminName = await showDialog<String?>(
        context: context,
        builder: (_) => const AdminBillingAuthDialog(),
      );

      if (adminName == null || adminName.isEmpty) {
        return; // Authorization canceled or failed
      }
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: this.context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Checkout ${widget.table.name}?'),
        content: Text(
          'Total Bill: ₹${grandTotal.toStringAsFixed(2)}\nAuthorized by Admin: $adminName\n\nThis will generate an official Bill document, mark ${activeOrders.length} order(s) as billed, and reset ${widget.table.name} back to AVAILABLE.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.staffPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Checkout & Bill'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final orderIds = activeOrders.map((o) => o.id).toList();

      // Consolidate bill items
      final List<BillItemModel> billItems = [];
      for (final order in activeOrders) {
        for (final item in order.items) {
          billItems.add(BillItemModel(
            itemId: item.itemId,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            totalPrice: item.totalPrice,
          ));
        }
      }

      final newBill = BillModel(
        id: '',
        billNumber: '',
        tableId: widget.table.id,
        tableName: widget.table.name,
        sessionId: activeOrders.first.sessionId,
        orderIds: orderIds,
        items: billItems,
        totalAmount: grandTotal,
        billedBy: adminName,
      );

      final billService = BillService();
      try {
        await billService.createBillAndCheckoutSession(newBill, orderIds);
        navigator.pop(); // Close session hub
        messenger.showSnackBar(
          SnackBar(
            content: Text('${widget.table.name} billed & saved to Bills collection! Authorized by $adminName'),
            backgroundColor: AppColors.staffPrimary,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to generate bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.staffPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_restaurant,
                    color: AppColors.staffPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.table.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Capacity: ${widget.table.capacity} Persons',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 8),
                      SizedBox(width: 6),
                      Text(
                        'OCCUPIED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Stream of Table Active Orders
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: orderProvider.getTableActiveOrdersStream(widget.table.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activeOrders = snapshot.data ?? [];
                if (activeOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No active unbilled orders for this table.',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.staffPrimary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Start New Order'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StaffCreateOrderScreen(initialTable: widget.table),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                double grandTotal = activeOrders.fold(0.0, (acc, o) => acc + o.totalAmount);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = activeOrders[index];
                          return _buildOrderCard(context, order, orderProvider);
                        },
                      ),
                    ),

                    // Bottom Summary & Actions Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Table Tab Total (${activeOrders.length} Order${activeOrders.length > 1 ? 's' : ''}):',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '₹${grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.staffPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: AppColors.staffPrimary),
                                      foregroundColor: AppColors.staffPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('+ Order Round'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StaffCreateOrderScreen(initialTable: widget.table),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 2,
                                    ),
                                    icon: const Icon(Icons.point_of_sale),
                                    label: const Text('Checkout & Bill'),
                                    onPressed: () => _handleCheckout(context, activeOrders, grandTotal),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, OrderProvider orderProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.staffPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.orderTag ?? 'Main Order',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.staffPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'By: ${order.createdBy}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Divider(height: 20),

            // Items Subcollection Stream
            StreamBuilder<List<OrderItemModel>>(
              stream: orderProvider.getOrderItemsStream(order.id),
              builder: (context, itemSnapshot) {
                if (itemSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }

                final items = itemSnapshot.data ?? order.items;
                if (items.isEmpty) {
                  return const Text('No items in this order.', style: TextStyle(color: Colors.grey, fontSize: 13));
                }

                return Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'R${item.roundNumber}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.name}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                          ),
                          const SizedBox(width: 8),
                          _buildItemStatusBadge(item.status),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: AppColors.staffPrimary),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.staffPrimary),
                label: const Text(
                  '+ Add Items to Order',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.staffPrimary),
                ),
                onPressed: () => _openAddItemModal(context, order),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemStatusBadge(String status) {
    Color bg = Colors.orange.shade50;
    Color fg = Colors.orange.shade800;
    if (status == 'Served') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (status == 'Preparing') {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _AddItemModalContent extends StatefulWidget {
  final OrderModel order;

  const _AddItemModalContent({
    required this.order,
  });

  @override
  State<_AddItemModalContent> createState() => _AddItemModalContentState();
}

class _AddItemModalContentState extends State<_AddItemModalContent> {
  final Map<String, int> _selectedQuantities = {};

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Items to ${widget.order.orderNumber}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<MenuItemModel>>(
              stream: menuProvider.getMenuItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.staffPrimary));
                }

                final menuItems = (snapshot.data ?? []).where((i) => i.isAvailable).toList();
                if (menuItems.isEmpty) {
                  return const Center(
                    child: Text('No menu items available.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final qty = _selectedQuantities[item.id] ?? 0;

                    return ListTile(
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (qty > 0) ...[
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  if (qty > 1) {
                                    _selectedQuantities[item.id] = qty - 1;
                                  } else {
                                    _selectedQuantities.remove(item.id);
                                  }
                                });
                              },
                            ),
                            Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColors.staffPrimary),
                            onPressed: () {
                              setState(() {
                                _selectedQuantities[item.id] = qty + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Action Button
          StreamBuilder<List<MenuItemModel>>(
            stream: menuProvider.getMenuItemsStream(),
            builder: (context, snapshot) {
              final menuItems = (snapshot.data ?? []).where((i) => i.isAvailable).toList();

              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.staffPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _selectedQuantities.isEmpty || orderProvider.isLoading
                          ? null
                          : () async {
                              List<OrderItemModel> newItems = [];
                              _selectedQuantities.forEach((itemId, quantity) {
                                final menuItem = menuItems.firstWhere((m) => m.id == itemId);
                                newItems.add(OrderItemModel(
                                  itemId: menuItem.id,
                                  name: menuItem.name,
                                  price: menuItem.price,
                                  quantity: quantity,
                                  roundNumber: 2, // Added round
                                ));
                              });

                              final success = await orderProvider.addItemsToOrder(
                                widget.order.id,
                                newItems,
                              );

                              if (context.mounted) {
                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Items appended to ${widget.order.orderNumber}!'),
                                      backgroundColor: AppColors.staffPrimary,
                                    ),
                                  );
                                }
                              }
                            },
                      child: orderProvider.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Append ${_selectedQuantities.length} Item(s) to Order'),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
