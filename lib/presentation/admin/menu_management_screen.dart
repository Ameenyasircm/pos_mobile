import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/models/menu_item_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/menu_provider.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditModal(BuildContext context, List<CategoryModel> categories, {MenuItemModel? itemToEdit}) {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one Category before creating Menu Items.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final isEditing = itemToEdit != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: itemToEdit?.name ?? '');
    final priceController = TextEditingController(text: itemToEdit?.price.toString() ?? '');
    final descriptionController = TextEditingController(text: itemToEdit?.description ?? '');
    
    String selectedCategoryId = itemToEdit?.categoryId ?? categories.first.id;
    bool isAvailable = itemToEdit?.isAvailable ?? true;

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
                            isEditing ? 'Edit Menu Item' : 'Add New Menu Item',
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

                      // Item Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          hintText: 'e.g. Cappuccino, Cheese Burger, Iced Latte',
                          prefixIcon: Icon(Icons.restaurant_menu_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter item name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCategoryId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Price Field
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: 'e.g. 120.00',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter price';
                          if (double.tryParse(v.trim()) == null) return 'Enter valid price number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description Field
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'e.g. Espresso with steamed milk and cocoa dusting',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Availability Switch
                      SwitchListTile(
                        title: const Text(
                          'In Stock / Available',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isAvailable ? 'Available for ordering' : 'Marked as Out of Stock',
                          style: TextStyle(
                            color: isAvailable ? AppColors.success : AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                        value: isAvailable,
                        activeTrackColor: AppColors.success,
                        onChanged: (val) {
                          setModalState(() {
                            isAvailable = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      Consumer<MenuProvider>(
                        builder: (context, menuProvider, child) {
                          return ElevatedButton(
                            onPressed: menuProvider.isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);

                                    final price = double.parse(priceController.text.trim());
                                    final categoryObj = categories.firstWhere(
                                      (c) => c.id == selectedCategoryId,
                                      orElse: () => categories.first,
                                    );

                                    bool success;
                                    if (isEditing) {
                                      final updated = itemToEdit.copyWith(
                                        name: nameController.text.trim(),
                                        price: price,
                                        categoryId: categoryObj.id,
                                        categoryName: categoryObj.name,
                                        description: descriptionController.text.trim(),
                                        isAvailable: isAvailable,
                                      );
                                      success = await menuProvider.updateMenuItem(updated);
                                    } else {
                                      final newItem = MenuItemModel(
                                        id: '',
                                        name: nameController.text.trim(),
                                        price: price,
                                        categoryId: categoryObj.id,
                                        categoryName: categoryObj.name,
                                        description: descriptionController.text.trim(),
                                        isAvailable: isAvailable,
                                      );
                                      success = await menuProvider.addMenuItem(newItem);
                                    }

                                    if (success) {
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing ? 'Item updated' : 'Item added'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(menuProvider.errorMessage ?? 'Operation failed'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                            child: menuProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isEditing ? 'UPDATE ITEM' : 'ADD ITEM'),
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

  void _confirmDeleteItem(BuildContext context, MenuItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Menu Item'),
          ],
        ),
        content: Text('Are you sure you want to delete "${item.name}"?'),
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
              final success = await Provider.of<MenuProvider>(context, listen: false).deleteMenuItem(item.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? '${item.name} deleted.' : 'Failed to delete item.'),
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
    final menuProvider = Provider.of<MenuProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Add Menu Item',
            onPressed: () {
              catProvider.getCategoriesStream().first.then((categories) {
                if (context.mounted) {
                  _showAddEditModal(context, categories);
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<List<CategoryModel>>(
        stream: catProvider.getCategoriesStream(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          return FloatingActionButton.extended(
            onPressed: () => _showAddEditModal(context, categories),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Menu Item'),
          );
        },
      ),
      body: Column(
        children: [
          // Search & Category Filter Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.background,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => menuProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search food menu by name or description...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              menuProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Category Filter Chips
                StreamBuilder<List<CategoryModel>>(
                  stream: catProvider.getCategoriesStream(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All Categories'),
                            selected: menuProvider.selectedCategoryId.isEmpty,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: menuProvider.selectedCategoryId.isEmpty ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) menuProvider.setSelectedCategoryId('');
                            },
                          ),
                          const SizedBox(width: 8),
                          ...categories.map((cat) {
                            final isSelected = menuProvider.selectedCategoryId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(cat.name),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (selected) {
                                  menuProvider.setSelectedCategoryId(selected ? cat.id : '');
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Menu Items Stream
          Expanded(
            child: StreamBuilder<List<MenuItemModel>>(
              stream: menuProvider.getMenuItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading menu items: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No menu item found matching "${_searchController.text}"'
                              : 'No menu items added yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<CategoryModel>>(
                          stream: catProvider.getCategoriesStream(),
                          builder: (context, catSnap) {
                            final categories = catSnap.data ?? [];
                            return OutlinedButton.icon(
                              onPressed: () => _showAddEditModal(context, categories),
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Menu Item'),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: item.isAvailable ? AppColors.cardBorder : AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fastfood_rounded, color: Color(0xFF2E7D32), size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: item.isAvailable ? AppColors.textPrimary : AppColors.textMuted,
                                            decoration: item.isAvailable ? null : TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₹${item.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.categoryName,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.isAvailable
                                              ? AppColors.success.withValues(alpha: 0.12)
                                              : AppColors.error.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.isAvailable ? 'AVAILABLE' : 'OUT OF STOCK',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: item.isAvailable ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.description,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  catProvider.getCategoriesStream().first.then((cats) {
                                    if (context.mounted) {
                                      _showAddEditModal(context, cats, itemToEdit: item);
                                    }
                                  });
                                } else if (val == 'toggle') {
                                  menuProvider.toggleMenuItemAvailability(item.id, item.isAvailable);
                                } else if (val == 'delete') {
                                  _confirmDeleteItem(context, item);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.isAvailable ? Icons.do_not_disturb_alt_rounded : Icons.check_circle_outline_rounded,
                                        color: item.isAvailable ? AppColors.warning : AppColors.success,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(item.isAvailable ? 'Mark Out of Stock' : 'Mark Available'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                                      SizedBox(width: 10),
                                      Text('Edit Item'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                      SizedBox(width: 10),
                                      Text('Delete Item', style: TextStyle(color: AppColors.error)),
                                    ],
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
