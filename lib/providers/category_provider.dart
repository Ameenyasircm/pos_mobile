import 'package:flutter/foundation.dart';
import '../data/models/category_model.dart';
import '../data/services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Stream<List<CategoryModel>> getCategoriesStream() {
    return _service.getCategoriesStream().map((categories) {
      if (_searchQuery.trim().isEmpty) return categories;
      final q = _searchQuery.trim().toLowerCase();
      return categories.where((c) => c.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<bool> addCategory(CategoryModel category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addCategory(category);
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

  Future<bool> updateCategory(CategoryModel category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateCategory(category);
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

  Future<bool> toggleCategoryStatus(String id, bool currentStatus) async {
    try {
      await _service.toggleCategoryStatus(id, !currentStatus);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update category status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteCategory(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete category: $e';
      notifyListeners();
      return false;
    }
  }
}
