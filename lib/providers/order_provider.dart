import 'package:flutter/foundation.dart';
import '../data/models/order_model.dart';
import '../data/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = ''; // Empty string means "All Statuses"

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Stream<List<OrderModel>> getOrdersStream() {
    return _service.getOrdersStream().map((orders) {
      var filtered = orders;
      if (_statusFilter.isNotEmpty) {
        filtered = filtered.where((o) => o.status.toLowerCase() == _statusFilter.toLowerCase()).toList();
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        filtered = filtered.where((o) {
          return o.orderNumber.toLowerCase().contains(q) ||
              o.tableName.toLowerCase().contains(q) ||
              o.createdBy.toLowerCase().contains(q) ||
              (o.orderTag != null && o.orderTag!.toLowerCase().contains(q));
        }).toList();
      }
      return filtered;
    });
  }

  Stream<List<OrderItemModel>> getOrderItemsStream(String orderId) {
    return _service.getOrderItemsStream(orderId);
  }

  Stream<List<OrderModel>> getTableActiveOrdersStream(String tableId) {
    return _service.getTableActiveOrdersStream(tableId);
  }

  Future<bool> createOrder(OrderModel order, [List<OrderItemModel>? items]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderItems = items ?? order.items;
      await _service.createOrder(order, orderItems);
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

  Future<bool> addItemsToOrder(String orderId, List<OrderItemModel> newItems, {int roundNumber = 2}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addItemsToOrder(orderId, newItems, roundNumber: roundNumber);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add items: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderItemStatus(String orderId, String itemDocId, String newStatus) async {
    try {
      await _service.updateOrderItemStatus(orderId, itemDocId, newStatus);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update item status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _service.updateOrderStatus(orderId, newStatus);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update order status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkoutTableSession(String tableId, List<String> orderIds, {String? billedBy}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.checkoutTableSession(tableId, orderIds, billedBy: billedBy);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to checkout table: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteOrder(orderId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete order: $e';
      notifyListeners();
      return false;
    }
  }
}

