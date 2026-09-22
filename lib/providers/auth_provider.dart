import 'package:flutter/foundation.dart';
import '../data/models/admin_model.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  AuthSession? get currentSession => _currentSession;
  AdminModel? get currentAdmin => _currentSession?.adminProfile;
  UserModel? get currentStaff => _currentSession?.staffProfile;
  bool get isAdmin => _currentSession?.isAdmin ?? false;
  bool get isStaff => _currentSession != null && !_currentSession!.isAdmin;
  bool get isAuthenticated => _currentSession != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Unified login for Admin and Staff
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSession = await _authService.login(phone, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Automatically verifies saved session from SharedPreferences on app launch
  Future<bool> checkSavedSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSession = await _authService.autoVerifySession();
      _isLoading = false;
      notifyListeners();
      return _currentSession != null;
    } catch (e) {
      _currentSession = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> seedDemoAdmin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final admin = await _authService.seedDemoAdmin();
      _currentSession = AuthSession(
        adminProfile: admin,
        role: 'admin',
        isAdmin: true,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to seed demo admin: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentSession = null;
    _errorMessage = null;
    notifyListeners();
  }
}
