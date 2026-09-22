import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/table_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';
import 'staff_orders_screen.dart';

class StaffCreateOrderScreen extends StatefulWidget {
  final TableModel? initialTable;

  const StaffCreateOrderScreen({super.key, this.initialTable});

  @override
  State<StaffCreateOrderScreen> createState() => _StaffCreateOrderScreenState();
}

class _StaffCreateOrderScreenState extends State<StaffCreateOrderScreen> {
  final Map<String, int> _orderQuantities = {};
  String? _selectedTableId;
  String _selectedTableName = 'Select Table';
  String _selectedOrderTag = 'Main Order';

  final List<String> _presetOrderTags = [
    'Main Order',
    'Round 1',
    'Round 2',
    'Drinks Round',
    'Dessert Round',
    'Guest A',
    'Guest B',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTable != null) {
      _selectedTableId = widget.initialTable!.id;
      _selectedTableName = widget.initialTable!.name;
    }
  }

  int get _totalItemCount {
    int count = 0;
    for (final qty in _orderQuantities.values) {
      count += qty;
    }
    return count;
  }

  Future<void> _handlePlaceOrder(BuildContext context, List<MenuItemModel> allAvailableItems) async {
    if (_selectedTableId == null || _selectedTableId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a dining table for this order.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_totalItemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 menu item to place an order.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final String staffName = authProvider.currentSession?.displayName ?? 'Staff';

    // Build OrderItemModel list
    final List<OrderItemModel> orderItems = [];
    double calculatedTotal = 0.0;

    _orderQuantities.forEach((itemId, qty) {
      if (qty > 0) {
        final item = allAvailableItems.firstWhere((i) => i.id == itemId);
        orderItems.add(
          OrderItemModel(
            itemId: item.id,
            name: item.name,
            price: item.price,
            quantity: qty,
            status: 'Pending',
            roundNumber: 1,
          ),
        );
        calculatedTotal += (item.price * qty);
      }
    });

    final newOrder = OrderModel(
      id: '',
      orderNumber: '#1001',
      tableId: _selectedTableId,
      tableName: _selectedTableName,
      orderTag: _selectedOrderTag,
      totalAmount: calculatedTotal,
      status: 'Pending',
      createdBy: staffName,
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await orderProvider.createOrder(newOrder, orderItems);

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order ($_selectedOrderTag) created for $_selectedTableName! Total: ₹${calculatedTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.staffPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const StaffOrdersScreen()),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to place order.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final tableProvider = Provider.of<TableProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.staffBackground,
      appBar: AppBar(
        backgroundColor: AppColors.staffPrimary,
        foregroundColor: Colors.white,
        title: const Text('Create New Order'),
      ),
      body: Column(
        children: [
          // Table & Order Tag Selector Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: StreamBuilder<List<TableModel>>(
              stream: tableProvider.getTablesStream(),
              builder: (context, snapshot) {
                final tables = snapshot.data ?? [];

                // Auto-select first table if none selected yet
                if (_selectedTableId == null && tables.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedTableId == null) {
                      setState(() {
                        _selectedTableId = tables.first.id;
                        _selectedTableName = tables.first.name;
                      });
                    }
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Dining Table (Required) & Round Tag',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedTableId,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.table_restaurant_rounded, color: AppColors.staffPrimary),
                              fillColor: AppColors.staffBackground,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            hint: const Text('Select Table', overflow: TextOverflow.ellipsis),
                            items: tables.map((tbl) {
                              final isOccupied = tbl.status.toLowerCase() == 'occupied';
                              return DropdownMenuItem<String>(
                                value: tbl.id,
                                child: Text(
                                  '${tbl.name}${isOccupied ? ' (BUSY)' : ''}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: isOccupied ? AppColors.error : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedTableId = val;
                                  final matchingTbl = tables.firstWhere((t) => t.id == val, orElse: () => tables.first);
                                  _selectedTableName = matchingTbl.name;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedOrderTag,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.staffPrimary),
                              fillColor: AppColors.staffBackground,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            items: _presetOrderTags.map((tag) {
                              return DropdownMenuItem<String>(
                                value: tag,
                                child: Text(
                                  tag,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedOrderTag = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Menu Items Stream with Quantity Controls
          Expanded(
            child: StreamBuilder<List<MenuItemModel>>(
              stream: menuProvider.getMenuItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.staffPrimary));
                }

                final allItems = snapshot.data ?? [];
                final availableItems = allItems.where((i) => i.isAvailable).toList();

                if (availableItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No available menu items found to order.',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableItems.length,
                  itemBuilder: (context, index) {
                    final item = availableItems[index];
                    final qty = _orderQuantities[item.id] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: qty > 0 ? AppColors.staffPrimary : Colors.grey.shade300,
                          width: qty > 0 ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.price.toStringAsFixed(2)} • ${item.categoryName}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.staffPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: qty > 0
                                      ? () {
                                          setState(() {
                                            if (qty == 1) {
                                              _orderQuantities.remove(item.id);
                                            } else {
                                              _orderQuantities[item.id] = qty - 1;
                                            }
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline_rounded),
                                  color: AppColors.staffPrimary,
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _orderQuantities[item.id] = qty + 1;
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline_rounded),
                                  color: AppColors.staffPrimary,
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

          // Bottom Order Summary Bar
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              final menuProv = Provider.of<MenuProvider>(context, listen: false);

              return StreamBuilder<List<MenuItemModel>>(
                stream: menuProv.getMenuItemsStream(),
                builder: (context, snapshot) {
                  final availableItems = (snapshot.data ?? []).where((i) => i.isAvailable).toList();
                  double calculatedTotal = 0.0;
                  for (var item in availableItems) {
                    final qty = _orderQuantities[item.id] ?? 0;
                    calculatedTotal += (item.price * qty);
                  }

                  return Container(
                    padding: const EdgeInsets.all(18),
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
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Items: $_totalItemCount',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            Text(
                              '₹${calculatedTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.staffPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.staffPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: orderProvider.isLoading
                                ? null
                                : () => _handlePlaceOrder(context, availableItems),
                            child: orderProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('CONFIRM ORDER'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

