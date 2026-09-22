import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthSession {
  final AdminModel? adminProfile;
  final UserModel? staffProfile;
  final String role;
  final bool isAdmin;

  AuthSession({
    this.adminProfile,
    this.staffProfile,
    required this.role,
    required this.isAdmin,
  });

  String get displayName => isAdmin
      ? (adminProfile?.name ?? 'Admin')
      : (staffProfile?.name ?? 'Staff');
}

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _keyLoggedInPhone = 'logged_in_phone';
  static const String _keyLoggedInRole = 'logged_in_role';

  /// Performs Unified Authentication:
  /// Queries 'admins' collection first. If not found, queries 'users' collection.
  Future<AuthSession> login(String phone, String password) async {
    final cleanPhone = phone.trim();
    final cleanPassword = password.trim();

    // 1. Check admins collection first
    final adminQuery = await _firestore
        .collection(AppConstants.collectionAdmins)
        .where('phone', isEqualTo: cleanPhone)
        .limit(1)
        .get();

    if (adminQuery.docs.isNotEmpty) {
      final doc = adminQuery.docs.first;
      final data = doc.data();

      if (data['isActive'] == false) {
        throw AuthException('This admin account is deactivated.');
      }

      if (data['password'] != cleanPassword) {
        throw AuthException('Incorrect password. Please try again.');
      }

      final currentTimestamp = Timestamp.now();
      await doc.reference.update({
        'lastLogin': currentTimestamp,
      });

      data['lastLogin'] = currentTimestamp;
      final adminModel = AdminModel.fromMap(data, doc.id);

      await _saveSession(cleanPhone, 'admin');

      return AuthSession(
        adminProfile: adminModel,
        role: 'admin',
        isAdmin: true,
      );
    }

    // 2. Check users (waiters/staff) collection
    final userQuery = await _firestore
        .collection(AppConstants.collectionUsers)
        .where('phone', isEqualTo: cleanPhone)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final doc = userQuery.docs.first;
      final data = doc.data();

      if (data['isActive'] == false) {
        throw AuthException('Your staff account is blocked. Please contact admin.');
      }

      if (data['password'] != cleanPassword) {
        throw AuthException('Incorrect password. Please try again.');
      }

      final currentTimestamp = Timestamp.now();
      await doc.reference.update({
        'lastLogin': currentTimestamp,
      });

      data['lastLogin'] = currentTimestamp;
      final userModel = UserModel.fromMap(data, doc.id);
      final role = userModel.role.isNotEmpty ? userModel.role : 'waiter';

      await _saveSession(cleanPhone, role);

      return AuthSession(
        staffProfile: userModel,
        role: role,
        isAdmin: false,
      );
    }

    throw AuthException('No admin or staff account found with this phone number.');
  }

  /// Auto verifies saved session from SharedPreferences on app launch
  Future<AuthSession?> autoVerifySession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_keyLoggedInPhone);
      final savedRole = prefs.getString(_keyLoggedInRole);

      if (savedPhone == null || savedPhone.isEmpty || savedRole == null) {
        return null;
      }

      if (savedRole == 'admin') {
        final adminQuery = await _firestore
            .collection(AppConstants.collectionAdmins)
            .where('phone', isEqualTo: savedPhone)
            .limit(1)
            .get();

        if (adminQuery.docs.isEmpty) {
          await _clearSession();
          return null;
        }

        final doc = adminQuery.docs.first;
        final data = doc.data();

        if (data['isActive'] == false) {
          await _clearSession();
          return null;
        }

        final currentTimestamp = Timestamp.now();
        await doc.reference.update({
          'lastLogin': currentTimestamp,
        });

        data['lastLogin'] = currentTimestamp;
        return AuthSession(
          adminProfile: AdminModel.fromMap(data, doc.id),
          role: 'admin',
          isAdmin: true,
        );
      } else {
        // Staff user
        final userQuery = await _firestore
            .collection(AppConstants.collectionUsers)
            .where('phone', isEqualTo: savedPhone)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          await _clearSession();
          return null;
        }

        final doc = userQuery.docs.first;
        final data = doc.data();

        if (data['isActive'] == false) {
          await _clearSession();
          return null;
        }

        final currentTimestamp = Timestamp.now();
        await doc.reference.update({
          'lastLogin': currentTimestamp,
        });

        data['lastLogin'] = currentTimestamp;
        final userModel = UserModel.fromMap(data, doc.id);

        return AuthSession(
          staffProfile: userModel,
          role: userModel.role,
          isAdmin: false,
        );
      }
    } catch (e) {
      return null;
    }
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession(String phone, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoggedInPhone, phone);
    await prefs.setString(_keyLoggedInRole, role);
  }

  /// Clear session from SharedPreferences
  Future<void> logout() async {
    await _clearSession();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedInPhone);
    await prefs.remove(_keyLoggedInRole);
  }

  /// Legacy helper for admin seeding
  Future<AdminModel> seedDemoAdmin({
    String name = 'Ameen',
    String phone = '9876543210',
    String password = '123456',
  }) async {
    final existing = await _firestore
        .collection(AppConstants.collectionAdmins)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      await _saveSession(phone, 'admin');
      return AdminModel.fromMap(doc.data(), doc.id);
    }

    final docRef = await _firestore.collection(AppConstants.collectionAdmins).add({
      'name': name,
      'phone': phone,
      'password': password,
      'role': 'admin',
      'isActive': true,
      'lastLogin': Timestamp.now(),
    });

    await _saveSession(phone, 'admin');
    final snapshot = await docRef.get();
    return AdminModel.fromMap(snapshot.data()!, docRef.id);
  }
}
