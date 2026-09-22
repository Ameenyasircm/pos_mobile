import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/table_model.dart';
import '../../providers/table_provider.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  void _showAddEditModal(BuildContext context, {TableModel? tableToEdit}) {
    final isEditing = tableToEdit != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: tableToEdit?.name ?? '');
    final capacityController = TextEditingController(text: tableToEdit?.capacity.toString() ?? '4');
    String selectedStatus = tableToEdit?.status ?? 'available';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Dining Table' : 'Add Dining Table',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Table Name Field
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Table Name / Number',
                          hintText: 'e.g. Table 1, T-04, Outdoor 2',
                          prefixIcon: Icon(Icons.table_restaurant_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter table name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Capacity Field
                      TextFormField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Seating Capacity',
                          hintText: 'e.g. 2, 4, 6',
                          prefixIcon: Icon(Icons.event_seat_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter capacity';
                          if (int.tryParse(v.trim()) == null) return 'Enter valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Table Status',
                          prefixIcon: Icon(Icons.info_outline_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'available', child: Text('Available')),
                          DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                          DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedStatus = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      Consumer<TableProvider>(
                        builder: (context, tableProvider, child) {
                          return ElevatedButton(
                            onPressed: tableProvider.isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);

                                    final cap = int.parse(capacityController.text.trim());

                                    bool success;
                                    if (isEditing) {
                                      final updated = tableToEdit.copyWith(
                                        name: nameController.text.trim(),
                                        capacity: cap,
                                        status: selectedStatus,
                                      );
                                      success = await tableProvider.updateTable(updated);
                                    } else {
                                      final newTable = TableModel(
                                        id: '',
                                        name: nameController.text.trim(),
                                        capacity: cap,
                                        status: selectedStatus,
                                      );
                                      success = await tableProvider.addTable(newTable);
                                    }

                                    if (success) {
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing ? 'Table updated' : 'Table added'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(tableProvider.errorMessage ?? 'Operation failed'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                            child: tableProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isEditing ? 'UPDATE TABLE' : 'ADD TABLE'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTable(BuildContext context, TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Table'),
          ],
        ),
        content: Text('Are you sure you want to delete "${table.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              final success = await Provider.of<TableProvider>(context, listen: false).deleteTable(table.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? '${table.name} deleted.' : 'Failed to delete table.'),
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
    final tableProvider = Provider.of<TableProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            tooltip: 'Add Table',
            onPressed: () => _showAddEditModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Table'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.background,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => tableProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search tables by name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          tableProvider.setSearchQuery('');
                        },
                      )
                    : null,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Tables Grid Stream
          Expanded(
            child: StreamBuilder<List<TableModel>>(
              stream: tableProvider.getTablesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No table found matching "${_searchController.text}"'
                              : 'No dining tables added yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showAddEditModal(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Dining Table'),
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
                    childAspectRatio: 1.1,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    final statusColor = _getStatusColor(table.status);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
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
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showAddEditModal(context, tableToEdit: table);
                                    } else if (val == 'status_available') {
                                      tableProvider.updateTableStatus(table.id, 'available');
                                    } else if (val == 'status_occupied') {
                                      tableProvider.updateTableStatus(table.id, 'occupied');
                                    } else if (val == 'status_reserved') {
                                      tableProvider.updateTableStatus(table.id, 'reserved');
                                    } else if (val == 'delete') {
                                      _confirmDeleteTable(context, table);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'status_available',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark Available'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'status_occupied',
                                      child: Row(
                                        children: [
                                          Icon(Icons.do_not_disturb_on_outlined, color: AppColors.error, size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark Occupied'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'status_reserved',
                                      child: Row(
                                        children: [
                                          Icon(Icons.bookmark_outline_rounded, color: AppColors.warning, size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark Reserved'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, color: AppColors.info, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit Table'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                          SizedBox(width: 8),
                                          Text('Delete Table', style: TextStyle(color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              table.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Seats: ${table.capacity}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
}
