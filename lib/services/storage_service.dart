import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';
import '../models/savings_goal.dart';

/// Servicio de Almacenamiento Local y Sincronización
/// Persiste datos en SharedPreferences y mantiene esquemas listos para Supabase / Cloud Postgres.
class StorageService {
  static const String _keyProfile = 'finamax_user_profile';
  static const String _keyCards = 'finamax_credit_cards';
  static const String _keyTransactions = 'finamax_transactions';
  static const String _keyGoals = 'finamax_savings_goals';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Perfil de Usuario ---
  Future<void> saveUserProfile(UserProfile profile) async {
    await init();
    final jsonStr = jsonEncode(profile.toJson());
    await _prefs!.setString(_keyProfile, jsonStr);
  }

  Future<UserProfile?> getUserProfile() async {
    await init();
    final jsonStr = _prefs!.getString(_keyProfile);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- Tarjetas de Crédito ---
  Future<void> saveCreditCards(List<CreditCard> cards) async {
    await init();
    final list = cards.map((c) => c.toJson()).toList();
    await _prefs!.setString(_keyCards, jsonEncode(list));
  }

  Future<List<CreditCard>> getCreditCards() async {
    await init();
    final jsonStr = _prefs!.getString(_keyCards);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => CreditCard.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Transacciones / Gastos ---
  Future<void> saveTransactions(List<TransactionItem> transactions) async {
    await init();
    final list = transactions.map((t) => t.toJson()).toList();
    await _prefs!.setString(_keyTransactions, jsonEncode(list));
  }

  Future<List<TransactionItem>> getTransactions() async {
    await init();
    final jsonStr = _prefs!.getString(_keyTransactions);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => TransactionItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Metas de Ahorro ---
  Future<void> saveSavingsGoals(List<SavingsGoal> goals) async {
    await init();
    final list = goals.map((g) => g.toJson()).toList();
    await _prefs!.setString(_keyGoals, jsonEncode(list));
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    await init();
    final jsonStr = _prefs!.getString(_keyGoals);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => SavingsGoal.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Limpieza total / Logout ---
  Future<void> clearAll() async {
    await init();
    await _prefs!.clear();
  }

  // --- Poblado inicial de datos Demo realistas ---
  Future<void> populateSeedDataIfEmpty(String userId, String userEmail, String userName) async {
    await init();
    final existingProfile = await getUserProfile();
    if (existingProfile != null) return;

    final now = DateTime.now();

    // Perfil Demo
    final seedProfile = UserProfile(
      id: userId,
      email: userEmail,
      name: userName,
      currency: 'MXN',
      incomeType: 'quincenal',
      incomeAmount: 18500.0,
      nextPayDate: now.day <= 15 ? DateTime(now.year, now.month, 15) : DateTime(now.year, now.month, 30),
    );
    await saveUserProfile(seedProfile);

    // Tarjetas Demo
    // Tarjeta 1: Nu (Corte día 12, Pago día 2)
    // Tarjeta 2: BBVA Oro (Corte día 24, Pago día 14)
    final seedCards = [
      CreditCard(
        id: 'card-nu-1',
        userId: userId,
        bankName: 'Nu Bank',
        cardName: 'Nu Gold Mastercard',
        colorHex: '#8B5CF6', // Violeta
        cutOffDay: 12,
        paymentDueDay: 2,
        creditLimit: 35000.0,
        currentBalance: 4250.0,
      ),
      CreditCard(
        id: 'card-bbva-2',
        userId: userId,
        bankName: 'BBVA',
        cardName: 'BBVA Oro Visa',
        colorHex: '#1E40AF', // Azul Real
        cutOffDay: 24,
        paymentDueDay: 14,
        creditLimit: 55000.0,
        currentBalance: 8700.0,
      ),
      CreditCard(
        id: 'card-amex-3',
        userId: userId,
        bankName: 'American Express',
        cardName: 'Amex Rewards Verde',
        colorHex: '#10B981', // Esmeralda
        cutOffDay: 5,
        paymentDueDay: 25,
        creditLimit: 40000.0,
        currentBalance: 2100.0,
      ),
    ];
    await saveCreditCards(seedCards);

    // Gastos Demo
    final seedTransactions = [
      TransactionItem(
        id: 'tx-1',
        userId: userId,
        title: 'Supermercado Mensual',
        amount: 2450.0,
        category: 'Alimentación',
        date: now.subtract(const Duration(days: 1)),
        periodicity: 'quincenal',
        paymentMethod: 'tarjeta_credito',
        creditCardId: 'card-nu-1',
      ),
      TransactionItem(
        id: 'tx-2',
        userId: userId,
        title: 'Gasolina y Transporte',
        amount: 850.0,
        category: 'Transporte',
        date: now.subtract(const Duration(hours: 18)),
        periodicity: 'semanal',
        paymentMethod: 'debito',
      ),
      TransactionItem(
        id: 'tx-3',
        userId: userId,
        title: 'Suscripciones y Cloud',
        amount: 399.0,
        category: 'Servicios',
        date: now.subtract(const Duration(days: 3)),
        periodicity: 'mensual',
        paymentMethod: 'tarjeta_credito',
        creditCardId: 'card-bbva-2',
      ),
      TransactionItem(
        id: 'tx-4',
        userId: userId,
        title: 'Almuerzo Ejecutivo',
        amount: 185.0,
        category: 'Alimentación',
        date: now,
        periodicity: 'diario',
        paymentMethod: 'efectivo',
      ),
    ];
    await saveTransactions(seedTransactions);

    // Metas de Ahorro Demo
    final seedGoals = [
      SavingsGoal(
        id: 'goal-1',
        userId: userId,
        title: 'Fondo de Emergencia (3 meses)',
        targetAmount: 50000.0,
        currentAmount: 28500.0,
        targetDate: now.add(const Duration(days: 120)),
        colorHex: '#10B981',
      ),
      SavingsGoal(
        id: 'goal-2',
        userId: userId,
        title: 'Viaje a Japón 🇯🇵',
        targetAmount: 45000.0,
        currentAmount: 16000.0,
        targetDate: now.add(const Duration(days: 180)),
        colorHex: '#8B5CF6',
      ),
    ];
    await saveSavingsGoals(seedGoals);
  }
}
