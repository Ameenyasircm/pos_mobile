import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/table_model.dart';
import '../../data/models/order_model.dart';
import '../../providers/table_provider.dart';
import '../../providers/order_provider.dart';
import 'staff_create_order_screen.dart';
import 'table_session_hub_dialog.dart';

class StaffTablesScreen extends StatelessWidget {
  final bool isOrderSelectionMode;

  const StaffTablesScreen({super.key, this.isOrderSelectionMode = false});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'occupied':
        return AppColors.error;
      case 'reserved':
        return AppColors.warning;
      case 'available':
      default:
        return AppColors.success;
    }
  }

  void _handleTableTap(BuildContext context, TableModel table) {
    if (table.status.toLowerCase() == 'available') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StaffCreateOrderScreen(initialTable: table),
        ),
      );
    } else {
      // Occupied or Reserved -> Open Table Session Hub Modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TableSessionHubDialog(table: table),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableProvider = Provider.of<TableProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.staffBackground,
      appBar: AppBar(
        backgroundColor: AppColors.staffPrimary,
        foregroundColor: Colors.white,
        title: Text(isOrderSelectionMode ? 'Select Table to Order' : 'Dining Tables'),
      ),
      body: StreamBuilder<List<TableModel>>(
        stream: tableProvider.getTablesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.staffPrimary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading tables: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }

          final tables = snapshot.data ?? [];

          if (tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_restaurant_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No dining tables added by Admin yet.',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.15,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              final statusColor = _getStatusColor(table.status);
              final isOccupied = table.status.toLowerCase() == 'occupied';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: InkWell(
                  onTap: () => _handleTableTap(context, table),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.table_bar_rounded,
                                color: statusColor,
                                size: 22,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                table.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          table.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (isOccupied)
                          StreamBuilder<List<OrderModel>>(
                            stream: orderProvider.getTableActiveOrdersStream(table.id),
                            builder: (context, orderSnap) {
                              final activeOrders = orderSnap.data ?? [];
                              final total = activeOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
                              return Text(
                                '${activeOrders.length} Order${activeOrders.length != 1 ? 's' : ''} • ₹${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              );
                            },
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.event_seat_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${table.capacity} Seats',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

