import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    // Listen to Firebase Auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    _status =
        user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  // ── Sign Up ───────────────────────────────────────────────
  Future<bool> signUp({required String email, required String password}) async {
    try {
      _setLoading();
      await _authService.signUpWithEmail(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  // ── Sign In ───────────────────────────────────────────────
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading();
      await _authService.signInWithEmail(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  // ── Google Sign In ────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading();
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // User cancelled
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ── Get ID Token ──────────────────────────────────────────
  Future<String?> getIdToken() => _authService.getIdToken();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
