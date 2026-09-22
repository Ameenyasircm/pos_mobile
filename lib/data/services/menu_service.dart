import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuException implements Exception {
  final String message;
  MenuException(this.message);

  @override
  String toString() => message;
}

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'menu_items';

  /// Stream of all menu items
  Stream<List<MenuItemModel>> getMenuItemsStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// Add new menu item
  Future<void> addMenuItem(MenuItemModel item) async {
    final existing = await _firestore
        .collection(_collectionName)
        .where('name', isEqualTo: item.name.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw MenuException('A menu item with this name already exists.');
    }

    await _firestore.collection(_collectionName).add(item.toMap());
  }

  /// Update menu item
  Future<void> updateMenuItem(MenuItemModel item) async {
    final existing = await _firestore
        .collection(_collectionName)
        .where('name', isEqualTo: item.name.trim())
        .get();

    final conflicts = existing.docs.where((doc) => doc.id != item.id);
    if (conflicts.isNotEmpty) {
      throw MenuException('Another menu item with this name already exists.');
    }

    await _firestore.collection(_collectionName).doc(item.id).update({
      'name': item.name.trim(),
      'price': item.price,
      'categoryId': item.categoryId,
      'categoryName': item.categoryName,
      'description': item.description.trim(),
      'isAvailable': item.isAvailable,
    });
  }

  /// Toggle availability status
  Future<void> toggleMenuItemAvailability(String id, bool isAvailable) async {
    await _firestore.collection(_collectionName).doc(id).update({
      'isAvailable': isAvailable,
    });
  }

  /// Delete menu item
  Future<void> deleteMenuItem(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
}
