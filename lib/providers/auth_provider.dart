import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.idle;
  String _errorMessage = '';
  User? _user;

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isLoading => _status == AuthStatus.loading;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // ─── تسجيل الدخول ─────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    _setStatus(AuthStatus.loading);
    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
        expectedRole: expectedRole,
      );
      _user = credential?.user;
      _setStatus(AuthStatus.success);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e.code);
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = 'صار خطأ غير متوقع';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ─── إنشاء حساب ───────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    _setStatus(AuthStatus.loading);
    try {
      final credential = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _user = credential?.user;
      _setStatus(AuthStatus.success);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e.code);
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = 'صار خطأ غير متوقع';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ─── تسجيل الخروج ─────────────────────────────────────────
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _setStatus(AuthStatus.idle);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _setStatus(AuthStatus.idle);
  }
}
