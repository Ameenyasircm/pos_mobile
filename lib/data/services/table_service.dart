import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';

class TableException implements Exception {
  final String message;
  TableException(this.message);

  @override
  String toString() => message;
}

class TableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'tables';

  /// Stream of all tables
  Stream<List<TableModel>> getTablesStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TableModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// Add new table
  Future<void> addTable(TableModel table) async {
    final existing = await _firestore
        .collection(_collectionName)
        .where('name', isEqualTo: table.name.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw TableException('A table with this name already exists.');
    }

    await _firestore.collection(_collectionName).add(table.toMap());
  }

  /// Update table
  Future<void> updateTable(TableModel table) async {
    final existing = await _firestore
        .collection(_collectionName)
        .where('name', isEqualTo: table.name.trim())
        .get();

    final conflicts = existing.docs.where((doc) => doc.id != table.id);
    if (conflicts.isNotEmpty) {
      throw TableException('Another table with this name already exists.');
    }

    await _firestore.collection(_collectionName).doc(table.id).update({
      'name': table.name.trim(),
      'capacity': table.capacity,
      'status': table.status,
      'isActive': table.isActive,
    });
  }

  /// Update table occupancy/reservation status
  Future<void> updateTableStatus(String id, String newStatus) async {
    await _firestore.collection(_collectionName).doc(id).update({
      'status': newStatus,
    });
  }

  /// Delete table
  Future<void> deleteTable(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
}
