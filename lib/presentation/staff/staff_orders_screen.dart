import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import 'staff_create_order_screen.dart';

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'preparing':
        return const Color(0xFF0288D1);
      case 'served':
        return const Color(0xFF6A1B9A);
      case 'billed':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _confirmDeleteOrder(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Cancel / Delete Order'),
          ],
        ),
        content: Text('Are you sure you want to delete order "${order.orderNumber}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Order', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              final success = await Provider.of<OrderProvider>(context, listen: false).deleteOrder(order.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Order ${order.orderNumber} deleted.' : 'Failed to delete order.'),
                  backgroundColor: success ? AppColors.primary : AppColors.error,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.staffBackground,
      appBar: AppBar(
        backgroundColor: AppColors.staffPrimary,
        foregroundColor: Colors.white,
        title: const Text('Orders Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            tooltip: 'New Order',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StaffCreateOrderScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StaffCreateOrderScreen()),
          );
        },
        backgroundColor: AppColors.staffPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
      body: Column(
        children: [
          // Search & Status Filter Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => orderProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search by Order #, Table, Tag or Staff name...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.staffPrimary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              orderProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    fillColor: AppColors.staffBackground,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip(context, orderProvider, '', 'All Orders'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(context, orderProvider, 'Pending', 'Pending'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(context, orderProvider, 'Preparing', 'Preparing'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(context, orderProvider, 'Served', 'Served'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(context, orderProvider, 'Billed', 'Billed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders Stream List
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: orderProvider.getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.staffPrimary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading orders: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No orders found matching "${_searchController.text}"'
                              : 'No orders placed yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const StaffCreateOrderScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Order'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final statusColor = _getStatusColor(order.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Header: Number, Tag, Table Badge, Popup Menu
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.staffPrimary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        order.orderNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        order.orderTag ?? 'Main Order',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        order.tableName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'delete') {
                                      _confirmDeleteOrder(context, order);
                                    } else {
                                      orderProvider.updateOrderStatus(order.id, val);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'Pending',
                                      child: Row(
                                        children: [
                                          Icon(Icons.hourglass_empty_rounded, color: AppColors.warning, size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark Pending'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Preparing',
                                      child: Row(
                                        children: [
                                          Icon(Icons.soup_kitchen_rounded, color: Color(0xFF0288D1), size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark Preparing'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Served',
                                      child: Row(
                                        children: [
                                          Icon(Icons.room_service_rounded, color: Color(0xFF6A1B9A), size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark Served'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Billed',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark Billed'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                          SizedBox(width: 8),
                                          Text('Delete Order', style: TextStyle(color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Timestamp & Creator
                            Text(
                              'Placed by ${order.createdBy} • ${DateFormatter.formatTimestamp(order.createdAt)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Divider(height: 20),

                            // Items Subcollection Stream
                            StreamBuilder<List<OrderItemModel>>(
                              stream: orderProvider.getOrderItemsStream(order.id),
                              builder: (context, itemSnap) {
                                final items = itemSnap.data ?? order.items;
                                if (items.isEmpty) {
                                  return const Text('No items listed.', style: TextStyle(color: Colors.grey, fontSize: 13));
                                }

                                return Column(
                                  children: items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'R${item.roundNumber}',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${item.quantity}x  ${item.name}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '₹${item.totalPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const Divider(height: 20),

                            // Total Amount & Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Amount', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text(
                                      '₹${order.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.staffPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(BuildContext context, OrderProvider provider, String statusValue, String label) {
    final isSelected = provider.statusFilter.toLowerCase() == statusValue.toLowerCase();
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.staffPrimary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (selected) {
        provider.setStatusFilter(selected ? statusValue : '');
      },
    );
  }
}

