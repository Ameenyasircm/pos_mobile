import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String? id; // Subcollection document ID
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String status; // 'Pending', 'Preparing', 'Served', 'Cancelled'
  final int roundNumber;
  final dynamic addedAt;

  OrderItemModel({
    this.id,
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.status = 'Pending',
    this.roundNumber = 1,
    this.addedAt,
  });

  double get totalPrice => price * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return OrderItemModel(
      id: id ?? map['id'],
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 1,
      status: map['status'] ?? 'Pending',
      roundNumber: (map['roundNumber'] is num) ? (map['roundNumber'] as num).toInt() : 1,
      addedAt: map['addedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'status': status,
      'roundNumber': roundNumber,
      'addedAt': addedAt ?? FieldValue.serverTimestamp(),
    };
  }

  OrderItemModel copyWith({
    String? id,
    String? itemId,
    String? name,
    double? price,
    int? quantity,
    String? status,
    int? roundNumber,
    dynamic addedAt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      roundNumber: roundNumber ?? this.roundNumber,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String? tableId;
  final String tableName;
  final String? sessionId;
  final String? orderTag;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String status; // 'Pending', 'Preparing', 'Served', 'Billed', 'Completed', 'Cancelled'
  final bool isBilled;
  final String? billedBy;
  final dynamic billedAt;
  final String createdBy;
  final dynamic createdAt;
  final dynamic updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.tableId,
    required this.tableName,
    this.sessionId,
    this.orderTag,
    this.items = const [],
    required this.totalAmount,
    this.status = 'Pending',
    this.isBilled = false,
    this.billedBy,
    this.billedAt,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id, {List<OrderItemModel>? items}) {
    // Backward compatibility for legacy inline items array if subcollection is not present
    List<OrderItemModel> itemsList = items ?? [];
    if (itemsList.isEmpty && map['items'] is List) {
      var rawItems = map['items'] as List<dynamic>;
      itemsList = rawItems
          .map((i) => OrderItemModel.fromMap(Map<String, dynamic>.from(i)))
          .toList();
    }

    return OrderModel(
      id: id,
      orderNumber: map['orderNumber'] ?? '#1001',
      tableId: map['tableId'],
      tableName: map['tableName'] ?? 'Takeaway / Counter',
      sessionId: map['sessionId'],
      orderTag: map['orderTag'] ?? 'Main Order',
      items: itemsList,
      totalAmount: (map['totalAmount'] is num) ? (map['totalAmount'] as num).toDouble() : 0.0,
      status: map['status'] ?? 'Pending',
      isBilled: map['isBilled'] == true,
      billedBy: map['billedBy'],
      billedAt: map['billedAt'],
      createdBy: map['createdBy'] ?? 'Staff',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'tableId': tableId,
      'tableName': tableName,
      'sessionId': sessionId,
      'orderTag': orderTag ?? 'Main Order',
      'totalAmount': totalAmount,
      'status': status,
      'isBilled': isBilled,
      'billedBy': billedBy,
      'billedAt': billedAt,
      'createdBy': createdBy,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? tableId,
    String? tableName,
    String? sessionId,
    String? orderTag,
    List<OrderItemModel>? items,
    double? totalAmount,
    String? status,
    bool? isBilled,
    String? billedBy,
    dynamic billedAt,
    String? createdBy,
    dynamic createdAt,
    dynamic updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      sessionId: sessionId ?? this.sessionId,
      orderTag: orderTag ?? this.orderTag,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      isBilled: isBilled ?? this.isBilled,
      billedBy: billedBy ?? this.billedBy,
      billedAt: billedAt ?? this.billedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

