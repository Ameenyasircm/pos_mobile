import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderException implements Exception {
  final String message;
  OrderException(this.message);

  @override
  String toString() => message;
}

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ordersCollection = 'orders';
  static const String _tablesCollection = 'tables';

  /// Stream of all orders sorted by createdAt descending
  Stream<List<OrderModel>> getOrdersStream() {
    return _firestore
        .collection(_ordersCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return -1;
        if (b.createdAt == null) return 1;
        if (a.createdAt is Timestamp && b.createdAt is Timestamp) {
          return (b.createdAt as Timestamp).compareTo(a.createdAt as Timestamp);
        }
        return 0;
      });
      return list;
    });
  }

  /// Stream of items for a specific order subcollection
  Stream<List<OrderItemModel>> getOrderItemsStream(String orderId) {
    return _firestore
        .collection(_ordersCollection)
        .doc(orderId)
        .collection('items')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderItemModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
      return list;
    });
  }

  /// Stream of active unbilled orders for a specific table
  Stream<List<OrderModel>> getTableActiveOrdersStream(String tableId) {
    return _firestore
        .collection(_ordersCollection)
        .where('tableId', isEqualTo: tableId)
        .where('isBilled', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        if (a.createdAt == null) return -1;
        if (b.createdAt == null) return 1;
        if (a.createdAt is Timestamp && b.createdAt is Timestamp) {
          return (b.createdAt as Timestamp).compareTo(a.createdAt as Timestamp);
        }
        return 0;
      });
      return list;
    });
  }

  /// Create a new Order with Subcollection Items in Firestore
  Future<String> createOrder(OrderModel order, List<OrderItemModel> items) async {
    // Generate order number based on current count
    final countSnap = await _firestore.collection(_ordersCollection).get();
    final nextNumber = countSnap.docs.length + 1001;
    final generatedOrderNum = '#$nextNumber';

    String? sessionId = order.sessionId;
    if (order.tableId != null && (sessionId == null || sessionId.isEmpty)) {
      // Check if there's already an active session for this table
      final activeOrdersSnap = await _firestore
          .collection(_ordersCollection)
          .where('tableId', isEqualTo: order.tableId)
          .where('isBilled', isEqualTo: false)
          .limit(1)
          .get();

      if (activeOrdersSnap.docs.isNotEmpty) {
        sessionId = activeOrdersSnap.docs.first.data()['sessionId'] as String?;
      }

      sessionId ??= 'SESSION_${order.tableId}_${DateTime.now().millisecondsSinceEpoch}';
    }

    final double total = items.fold(0.0, (runningTotal, i) => runningTotal + i.totalPrice);

    final orderDocRef = _firestore.collection(_ordersCollection).doc();
    final finalOrder = order.copyWith(
      id: orderDocRef.id,
      orderNumber: generatedOrderNum,
      sessionId: sessionId,
      totalAmount: total,
    );

    final batch = _firestore.batch();
    batch.set(orderDocRef, finalOrder.toMap());

    for (final item in items) {
      final itemDocRef = orderDocRef.collection('items').doc();
      batch.set(itemDocRef, item.toMap());
    }

    // Update table status to OCCUPIED if applicable
    if (order.tableId != null) {
      final tableRef = _firestore.collection(_tablesCollection).doc(order.tableId);
      batch.update(tableRef, {'status': 'OCCUPIED'});
    }

    await batch.commit();
    return orderDocRef.id;
  }

  /// Add/Append items to an existing open Order
  Future<void> addItemsToOrder(String orderId, List<OrderItemModel> newItems, {int roundNumber = 2}) async {
    if (newItems.isEmpty) return;

    final orderRef = _firestore.collection(_ordersCollection).doc(orderId);
    final batch = _firestore.batch();

    double addedTotal = 0.0;
    for (final item in newItems) {
      final itemDocRef = orderRef.collection('items').doc();
      final itemWithRound = item.copyWith(
        roundNumber: roundNumber,
        status: 'Pending',
      );
      batch.set(itemDocRef, itemWithRound.toMap());
      addedTotal += item.totalPrice;
    }

    batch.update(orderRef, {
      'totalAmount': FieldValue.increment(addedTotal),
      'status': 'Pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Update individual subcollection Item Status (e.g. 'Pending' -> 'Preparing' -> 'Served')
  Future<void> updateOrderItemStatus(String orderId, String itemDocId, String newStatus) async {
    await _firestore
        .collection(_ordersCollection)
        .doc(orderId)
        .collection('items')
        .doc(itemDocId)
        .update({'status': newStatus});
  }

  /// Update main Order Status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection(_ordersCollection).doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Checkout and Bill Table: marks all active table orders as billed and sets table status to AVAILABLE
  Future<void> checkoutTableSession(String tableId, List<String> orderIds, {String? billedBy}) async {
    final batch = _firestore.batch();

    for (final id in orderIds) {
      final ref = _firestore.collection(_ordersCollection).doc(id);
      batch.update(ref, {
        'isBilled': true,
        'status': 'Billed',
        'billedBy': billedBy ?? 'Admin',
        'billedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (tableId.isNotEmpty) {
      final tableRef = _firestore.collection(_tablesCollection).doc(tableId);
      batch.update(tableRef, {'status': 'AVAILABLE'});
    }

    await batch.commit();
  }

  /// Delete Order and its items subcollection
  Future<void> deleteOrder(String orderId) async {
    final itemsSnap = await _firestore.collection(_ordersCollection).doc(orderId).collection('items').get();
    final batch = _firestore.batch();
    for (var doc in itemsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection(_ordersCollection).doc(orderId));
    await batch.commit();
  }
}

