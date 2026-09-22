import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

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

  /// Get real-time stream of users, filtered by search query
  Stream<List<UserModel>> getUsersStream() {
    return _userService.getUsersStream().map((users) {
      if (_searchQuery.trim().isEmpty) return users;
      final q = _searchQuery.trim().toLowerCase();
      return users.where((u) {
        return u.name.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<bool> addUser(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.addUser(user);
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

  Future<bool> updateUser(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.updateUser(user);
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

  Future<bool> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _userService.toggleUserStatus(userId, !currentStatus);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update user status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.deleteUser(userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete user: $e';
      notifyListeners();
      return false;
    }
  }
}
