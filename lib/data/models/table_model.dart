import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id;
  final String name; // e.g. "Table 1", "T-02"
  final int capacity; // e.g. 4
  final String status; // 'available', 'occupied', 'reserved'
  final bool isActive;
  final dynamic createdAt;

  TableModel({
    required this.id,
    required this.name,
    this.capacity = 4,
    this.status = 'available',
    this.isActive = true,
    this.createdAt,
  });

  factory TableModel.fromMap(Map<String, dynamic> map, String id) {
    return TableModel(
      id: id,
      name: map['name'] ?? '',
      capacity: (map['capacity'] is num) ? (map['capacity'] as num).toInt() : 4,
      status: map['status'] ?? 'available',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  TableModel copyWith({
    String? id,
    String? name,
    int? capacity,
    String? status,
    bool? isActive,
    dynamic createdAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
