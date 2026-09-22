import 'package:flutter/foundation.dart';
import '../data/models/table_model.dart';
import '../data/services/table_service.dart';

class TableProvider extends ChangeNotifier {
  final TableService _service = TableService();

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

  Stream<List<TableModel>> getTablesStream() {
    return _service.getTablesStream().map((tables) {
      if (_searchQuery.trim().isEmpty) return tables;
      final q = _searchQuery.trim().toLowerCase();
      return tables.where((t) => t.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<bool> addTable(TableModel table) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addTable(table);
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

  Future<bool> updateTable(TableModel table) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateTable(table);
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

  Future<bool> updateTableStatus(String id, String newStatus) async {
    try {
      await _service.updateTableStatus(id, newStatus);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update table status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTable(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteTable(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete table: $e';
      notifyListeners();
      return false;
    }
  }
}
