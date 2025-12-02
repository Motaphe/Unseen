import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unseen/services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    try {
      // Check if Firebase is initialized before listening
      try {
        _authService.authStateChanges.listen(
          (user) {
            _user = user;
            if (user != null) {
              _status = AuthStatus.authenticated;
            } else {
              _status = AuthStatus.unauthenticated;
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('❌ Auth state listener error: $error');
            _status = AuthStatus.error;
            _errorMessage = 'Authentication service unavailable';
            notifyListeners();
          },
          cancelOnError: false, // Keep listening even on error
        );
        debugPrint('✅ Auth state listener initialized');
      } catch (e) {
        debugPrint('❌ Failed to initialize auth state listener: $e');
        _status = AuthStatus.unauthenticated; // Default to unauthenticated, not error
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ AuthProvider initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      _status = AuthStatus.unauthenticated; // Default to unauthenticated
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      _errorMessage = null;
      await _authService.deleteAccount();
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
