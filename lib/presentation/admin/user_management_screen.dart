import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditUserModal(BuildContext context, {UserModel? userToEdit}) {
    final isEditing = userToEdit != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: userToEdit?.name ?? '');
    final phoneController = TextEditingController(text: userToEdit?.phone ?? '');
    final passwordController = TextEditingController(text: userToEdit?.password ?? '');
    String selectedRole = userToEdit?.role ?? 'waiter';
    bool isActive = userToEdit?.isActive ?? true;

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
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Staff User' : 'Add New Staff User',
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

                      // Name Field
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Staff Name',
                          hintText: 'e.g. Rahul Sharma',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter staff name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Phone Field
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g. 9999999999',
                          prefixIcon: Icon(Icons.phone_android_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter phone number';
                          if (v.trim().length < 8) return 'Enter valid phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter login password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter password';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'waiter', child: Text('Waiter')),
                          DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                          DropdownMenuItem(value: 'manager', child: Text('Manager')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedRole = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Active / Block Switch
                      SwitchListTile(
                        title: const Text(
                          'Account Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isActive ? 'Active (Allowed to sign in)' : 'Blocked (Access restricted)',
                          style: TextStyle(
                            color: isActive ? AppColors.success : AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                        value: isActive,
                        activeTrackColor: AppColors.success,
                        onChanged: (val) {
                          setModalState(() {
                            isActive = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return ElevatedButton(
                            onPressed: userProvider.isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);
                                    final currentAdminId = Provider.of<AuthProvider>(context, listen: false).currentAdmin?.id ?? 'admin';

                                    bool success;
                                    if (isEditing) {
                                      final updatedUser = userToEdit.copyWith(
                                        name: nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                        password: passwordController.text.trim(),
                                        role: selectedRole,
                                        isActive: isActive,
                                      );
                                      success = await userProvider.updateUser(updatedUser);
                                    } else {
                                      final newUser = UserModel(
                                        id: '',
                                        name: nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                        password: passwordController.text.trim(),
                                        role: selectedRole,
                                        isActive: isActive,
                                        createdBy: currentAdminId,
                                      );
                                      success = await userProvider.addUser(newUser);
                                    }

                                    if (success) {
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing ? 'User updated successfully' : 'User added successfully'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(userProvider.errorMessage ?? 'Operation failed'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                            child: userProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isEditing ? 'UPDATE STAFF USER' : 'ADD STAFF USER'),
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

  void _confirmDeleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Staff User'),
          ],
        ),
        content: Text('Are you sure you want to delete "${user.name}" (${user.phone})? This action cannot be undone.'),
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
              final success = await Provider.of<UserProvider>(context, listen: false).deleteUser(user.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? '${user.name} deleted.' : 'Failed to delete user.'),
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
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add User',
            onPressed: () => _showAddEditUserModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditUserModal(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.background,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => userProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search staff by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          userProvider.setSearchQuery('');
                        },
                      )
                    : null,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // User List Stream
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: userProvider.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading staff users: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No staff found matching "${_searchController.text}"'
                              : 'No staff users added yet.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showAddEditUserModal(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Staff User'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: user.isActive ? AppColors.cardBorder : AppColors.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            // Initials Avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: user.isActive
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.grey.shade200,
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'W',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: user.isActive ? AppColors.primary : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: user.isActive ? AppColors.textPrimary : AppColors.textMuted,
                                            decoration: user.isActive ? null : TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                      // Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: user.isActive
                                              ? AppColors.success.withValues(alpha: 0.12)
                                              : AppColors.error.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          user.isActive ? 'ACTIVE' : 'BLOCKED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: user.isActive ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.phone,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          user.role.toUpperCase(),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Popup Menu Actions
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showAddEditUserModal(context, userToEdit: user);
                                } else if (value == 'toggle') {
                                  userProvider.toggleUserStatus(user.id, user.isActive);
                                } else if (value == 'delete') {
                                  _confirmDeleteUser(context, user);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        user.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                        color: user.isActive ? AppColors.warning : AppColors.success,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(user.isActive ? 'Block Staff' : 'Unblock Staff'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                                      SizedBox(width: 10),
                                      Text('Edit Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                      SizedBox(width: 10),
                                      Text('Delete Staff', style: TextStyle(color: AppColors.error)),
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
