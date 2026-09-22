import 'package:cloud_firestore/cloud_firestore.dart';

class BillItemModel {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final double totalPrice;

  BillItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  factory BillItemModel.fromMap(Map<String, dynamic> map) {
    return BillItemModel(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 1,
      totalPrice: (map['totalPrice'] is num) ? (map['totalPrice'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}

class BillModel {
  final String id;
  final String billNumber;
  final String? tableId;
  final String tableName;
  final String? sessionId;
  final List<String> orderIds;
  final List<BillItemModel> items;
  final double totalAmount;
  final String paymentMethod; // 'Cash', 'UPI / Card', 'Split'
  final String billedBy;
  final dynamic createdAt;

  BillModel({
    required this.id,
    required this.billNumber,
    this.tableId,
    required this.tableName,
    this.sessionId,
    required this.orderIds,
    required this.items,
    required this.totalAmount,
    this.paymentMethod = 'Cash',
    required this.billedBy,
    this.createdAt,
  });

  factory BillModel.fromMap(Map<String, dynamic> map, String id) {
    var rawItems = map['items'] as List<dynamic>? ?? [];
    List<BillItemModel> itemsList = rawItems
        .map((i) => BillItemModel.fromMap(Map<String, dynamic>.from(i)))
        .toList();

    var rawOrderIds = map['orderIds'] as List<dynamic>? ?? [];
    List<String> orderIdsList = rawOrderIds.map((e) => e.toString()).toList();

    return BillModel(
      id: id,
      billNumber: map['billNumber'] ?? '#B-1001',
      tableId: map['tableId'],
      tableName: map['tableName'] ?? 'Dining Table',
      sessionId: map['sessionId'],
      orderIds: orderIdsList,
      items: itemsList,
      totalAmount: (map['totalAmount'] is num) ? (map['totalAmount'] as num).toDouble() : 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      billedBy: map['billedBy'] ?? 'Admin',
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'billNumber': billNumber,
      'tableId': tableId,
      'tableName': tableName,
      'sessionId': sessionId,
      'orderIds': orderIds,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'billedBy': billedBy,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
