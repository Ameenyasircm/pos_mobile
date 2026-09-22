import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryException implements Exception {
  final String message;
  CategoryException(this.message);

  @override
  String toString() => message;
}

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'categories';

  /// Stream of all categories
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// Add new category
  Future<void> addCategory(CategoryModel category) async {
    final existing = await _firestore
        .collection(_collectionName)
        .where('name', isEqualTo: category.name.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw CategoryException('A category with this name already exists.');
    }

    await _firestore.collection(_collectionName).add(category.toMap());
  }

  /// Update category
  Future<void> updateCategory(CategoryModel category) async {
    final existing = await _firestore
        .collection(_collectionName)
        .where('name', isEqualTo: category.name.trim())
        .get();

    final conflicts = existing.docs.where((doc) => doc.id != category.id);
    if (conflicts.isNotEmpty) {
      throw CategoryException('Another category with this name already exists.');
    }

    await _firestore.collection(_collectionName).doc(category.id).update({
      'name': category.name.trim(),
      'iconName': category.iconName,
      'isActive': category.isActive,
    });
  }

  /// Toggle active status
  Future<void> toggleCategoryStatus(String id, bool isActive) async {
    await _firestore.collection(_collectionName).doc(id).update({
      'isActive': isActive,
    });
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
}
