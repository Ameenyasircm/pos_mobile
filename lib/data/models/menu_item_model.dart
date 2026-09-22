import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String categoryName;
  final String description;
  final bool isAvailable;
  final dynamic createdAt;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    this.description = '',
    this.isAvailable = true,
    this.createdAt,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      description: map['description'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'isAvailable': isAvailable,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  MenuItemModel copyWith({
    String? id,
    String? name,
    double? price,
    String? categoryId,
    String? categoryName,
    String? description,
    bool? isAvailable,
    dynamic createdAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
