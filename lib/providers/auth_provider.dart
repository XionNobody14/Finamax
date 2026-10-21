import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Proveedor de Estado de Autenticación con Firebase y Firestore
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  StreamSubscription<User?>? _authSubscription;

  UserProfile? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  AuthProvider(this._authService, this._firestoreService) {
    _initAuthListener();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          final profile = await _firestoreService.getUserProfile(user.uid);
          if (profile != null) {
            _currentUser = profile;
          }
        } catch (_) {}
      } else if (_currentUser != null && !_currentUser!.id.startsWith('demo_local')) {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
    checkCurrentSession();
  }

  /// Verifica la sesión actual de Firebase Auth
  Future<void> checkCurrentSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _authService.currentFirebaseUser;
      if (user != null) {
        _currentUser = await _firestoreService.getUserProfile(user.uid);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia sesión con Email y Contraseña
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registro de un nuevo usuario
  Future<bool> register({
    required String email,
    required String name,
    required String password,
    required double incomeAmount,
    required String incomeType,
    required String currency,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        email: email,
        name: name,
        password: password,
        incomeAmount: incomeAmount,
        incomeType: incomeType,
        currency: currency,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Inicia en Modo Demo instantáneo
  Future<bool> loginAsDemo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.loginAsDemo();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualiza perfil de usuario
  Future<void> updateProfile(UserProfile updated) async {
    _currentUser = updated;
    await _firestoreService.saveUserProfile(updated);
    notifyListeners();
  }

  /// Cierra sesión
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
