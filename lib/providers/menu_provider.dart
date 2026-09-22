import 'package:flutter/foundation.dart';
import '../data/models/menu_item_model.dart';
import '../data/services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _service = MenuService();

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategoryId = ''; // Empty string means "All Categories"

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategoryId => _selectedCategoryId;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategoryId(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Stream<List<MenuItemModel>> getMenuItemsStream() {
    return _service.getMenuItemsStream().map((items) {
      var filtered = items;
      if (_selectedCategoryId.isNotEmpty) {
        filtered = filtered.where((i) => i.categoryId == _selectedCategoryId).toList();
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        filtered = filtered.where((i) {
          return i.name.toLowerCase().contains(q) ||
              i.categoryName.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q);
        }).toList();
      }
      return filtered;
    });
  }

  Future<bool> addMenuItem(MenuItemModel item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addMenuItem(item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMenuItem(MenuItemModel item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateMenuItem(item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleMenuItemAvailability(String id, bool currentStatus) async {
    try {
      await _service.toggleMenuItemAvailability(id, !currentStatus);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update item availability: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMenuItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteMenuItem(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete menu item: $e';
      notifyListeners();
      return false;
    }
  }
}
