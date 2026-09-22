import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class UserException implements Exception {
  final String message;
  UserException(this.message);

  @override
  String toString() => message;
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns real-time stream of users
  Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection(AppConstants.collectionUsers)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort manually by createdAt if present
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        if (a.createdAt is Timestamp && b.createdAt is Timestamp) {
          return (b.createdAt as Timestamp).compareTo(a.createdAt as Timestamp);
        }
        return 0;
      });
      return list;
    });
  }

  /// Add a new waiter user
  Future<void> addUser(UserModel user) async {
    final phoneQuery = await _firestore
        .collection(AppConstants.collectionUsers)
        .where('phone', isEqualTo: user.phone.trim())
        .limit(1)
        .get();

    if (phoneQuery.docs.isNotEmpty) {
      throw UserException('A user with this phone number already exists.');
    }

    await _firestore
        .collection(AppConstants.collectionUsers)
        .add(user.toMap());
  }

  /// Update an existing user
  Future<void> updateUser(UserModel user) async {
    // Check if phone number is changed and conflicts with another user
    final phoneQuery = await _firestore
        .collection(AppConstants.collectionUsers)
        .where('phone', isEqualTo: user.phone.trim())
        .get();

    final conflictingDocs = phoneQuery.docs.where((doc) => doc.id != user.id);
    if (conflictingDocs.isNotEmpty) {
      throw UserException('Another user with this phone number already exists.');
    }

    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.id)
        .update({
      'name': user.name.trim(),
      'phone': user.phone.trim(),
      'password': user.password.trim(),
      'role': user.role,
      'isActive': user.isActive,
    });
  }

  /// Toggle active/blocked status
  Future<void> toggleUserStatus(String userId, bool newStatus) async {
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .update({'isActive': newStatus});
  }

  /// Delete a user document
  Future<void> deleteUser(String userId) async {
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .delete();
  }
}
