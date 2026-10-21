import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

/// Servicio de Autenticación con Firebase Auth en FinamaX
/// Proporciona autenticación simétrica para usuarios comunes (sin roles administrativos)
/// y sincronización directa con Cloud Firestore.
class AuthService {
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  AuthService({
    FirebaseAuth? auth,
    required FirestoreService firestoreService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService;

  /// Stream del estado de autenticación en tiempo real
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actualmente autenticado en Firebase Auth
  User? get currentFirebaseUser => _auth.currentUser;

  /// Retorna si hay una sesión activa
  bool get isAuthenticated => _auth.currentUser != null;

  /// Traduce excepciones de FirebaseAuth a mensajes legibles en español
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'configuration-not-found':
        return 'La configuración del proveedor de autenticación aún se está propagando en Firebase. Espera unos momentos e intenta de nuevo.';
      case 'operation-not-allowed':
        return 'El proveedor de inicio de sesión con Correo y Contraseña está en proceso de activación en Firebase Console. Espera un momento o verifica Authentication > Sign-in method.';
      case 'user-not-found':
        return 'No existe una cuenta registrada con este correo electrónico.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Credenciales incorrectas. Verifica tu correo y contraseña.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta asociada a este correo electrónico.';
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido inhabilitada temporalmente.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu acceso a internet.';
      default:
        return e.message ?? 'Ocurrió un error de autenticación (${e.code}).';
    }
  }

  /// Inicia sesión con Correo y Contraseña
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Por favor completa todos los campos.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('No se pudo obtener el usuario autenticado.');
      }

      // Obtener o inicializar perfil en Firestore
      UserProfile? profile = await _firestoreService.getUserProfile(user.uid);
      if (profile == null) {
        final now = DateTime.now();
        profile = UserProfile(
          id: user.uid,
          email: normalizedEmail,
          name: normalizedEmail.split('@').first.toUpperCase(),
          currency: 'MXN',
          incomeType: 'quincenal',
          incomeAmount: 20000.0,
          nextPayDate: now.day <= 15
              ? DateTime(now.year, now.month, 15)
              : DateTime(now.year, now.month, 28),
        );
        await _firestoreService.saveUserProfile(profile);
      }

      return profile;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService.login] FirebaseAuthException (${e.code}): ${e.message}');
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('[AuthService.login] Unexpected error: $e');
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Registro de un nuevo usuario
  Future<UserProfile> register({
    required String email,
    required String name,
    required String password,
    required double incomeAmount,
    required String incomeType,
    required String currency,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      // Actualizar nombre visible en Firebase Auth
      await user.updateDisplayName(name.trim());

      final now = DateTime.now();
      final profile = UserProfile(
        id: user.uid,
        email: normalizedEmail,
        name: name.trim().isEmpty ? 'Usuario FinamaX' : name.trim(),
        currency: currency,
        incomeType: incomeType,
        incomeAmount: incomeAmount,
        nextPayDate: now.day <= 15
            ? DateTime(now.year, now.month, 15)
            : DateTime(now.year, now.month, 28),
      );

      // Guardar en Firestore e inicializar datos base
      await _firestoreService.saveUserProfile(profile);
      await _firestoreService.seedInitialUserDataIfEmpty(
        user.uid,
        normalizedEmail,
        profile.name,
        incomeAmount,
        incomeType,
        currency,
      );

      return profile;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService.register] FirebaseAuthException (${e.code}): ${e.message}');
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('[AuthService.register] Unexpected error: $e');
      throw Exception('Error en el registro: $e');
    }
  }

  /// Inicio de Sesión Rápido / Modo Demo
  Future<UserProfile> loginAsDemo() async {
    const demoEmail = 'demo@finamax.app';
    const demoPassword = 'FinamaxDemoPassword123!';

    try {
      return await login(email: demoEmail, password: demoPassword);
    } catch (_) {
      // Si la cuenta demo aún no existe en Firebase, la registramos automáticamente
      try {
        return await register(
          email: demoEmail,
          name: 'Usuario Demo FinamaX',
          password: demoPassword,
          incomeAmount: 18500.0,
          incomeType: 'quincenal',
          currency: 'MXN',
        );
      } catch (e) {
        // En caso de modo completamente offline o fallback local
        const localUid = 'demo_local_user';
        final now = DateTime.now();
        final profile = UserProfile(
          id: localUid,
          email: demoEmail,
          name: 'Usuario Demo FinamaX',
          currency: 'MXN',
          incomeType: 'quincenal',
          incomeAmount: 18500.0,
          nextPayDate: now.day <= 15
              ? DateTime(now.year, now.month, 15)
              : DateTime(now.year, now.month, 28),
        );
        return profile;
      }
    }
  }

  /// Cierre de sesión en Firebase Auth
  Future<void> logout() async {
    await _auth.signOut();
  }
}
