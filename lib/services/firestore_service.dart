import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';
import '../models/savings_goal.dart';

/// Servicio de sincronización y persistencia con Cloud Firestore en FinamaX
/// Organiza los datos bajo la jerarquía aislada: users/{userId}
/// y subcolecciones: expenses, credit_cards, savings_goals
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    // Configurar persistencia offline para que funcione en cualquier condición de red
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // Ignorar si ya fue inicializado con configuraciones previas
    }
  }

  // ==========================================
  // REFERENCIAS DE COLECCIONES POR USUARIO
  // ==========================================

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _expensesCol(String userId) =>
      _userDoc(userId).collection('expenses');

  CollectionReference<Map<String, dynamic>> _cardsCol(String userId) =>
      _userDoc(userId).collection('credit_cards');

  CollectionReference<Map<String, dynamic>> _goalsCol(String userId) =>
      _userDoc(userId).collection('savings_goals');

  // Helper para convertir DateTime/Timestamp de forma tolerante
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  // ==========================================
  // PERFIL DE USUARIO
  // ==========================================

  Future<void> saveUserProfile(UserProfile profile) async {
    final docRef = _userDoc(profile.id);
    await docRef.set({
      'id': profile.id,
      'email': profile.email,
      'name': profile.name,
      'currency': profile.currency,
      'incomeType': profile.incomeType,
      'incomeAmount': profile.incomeAmount,
      'nextPayDate': Timestamp.fromDate(profile.nextPayDate),
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final snap = await _userDoc(userId).get();
    if (!snap.exists || snap.data() == null) return null;
    final data = snap.data()!;
    return UserProfile(
      id: data['id'] as String? ?? userId,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? 'Usuario FinamaX',
      currency: data['currency'] as String? ?? 'MXN',
      incomeType: data['incomeType'] as String? ?? 'quincenal',
      incomeAmount: (data['incomeAmount'] as num?)?.toDouble() ?? 0.0,
      nextPayDate: _parseDateTime(data['nextPayDate']),
      createdAt: _parseDateTime(data['createdAt']),
    );
  }

  Stream<UserProfile?> streamUserProfile(String userId) {
    return _userDoc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = snap.data()!;
      return UserProfile(
        id: data['id'] as String? ?? userId,
        email: data['email'] as String? ?? '',
        name: data['name'] as String? ?? 'Usuario FinamaX',
        currency: data['currency'] as String? ?? 'MXN',
        incomeType: data['incomeType'] as String? ?? 'quincenal',
        incomeAmount: (data['incomeAmount'] as num?)?.toDouble() ?? 0.0,
        nextPayDate: _parseDateTime(data['nextPayDate']),
        createdAt: _parseDateTime(data['createdAt']),
      );
    });
  }

  // ==========================================
  // GASTOS Y TRANSACCIONES (EXPENSES)
  // ==========================================

  Stream<List<TransactionItem>> streamExpenses(String userId) {
    return _expensesCol(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((querySnap) {
      return querySnap.docs.map((doc) {
        final data = doc.data();
        return TransactionItem(
          id: doc.id,
          userId: userId,
          title: data['title'] as String? ?? 'Gasto sin título',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          category: data['category'] as String? ?? 'Otros',
          date: _parseDateTime(data['date']),
          periodicity: data['periodicity'] as String? ?? 'único',
          paymentMethod: data['paymentMethod'] as String? ?? 'efectivo',
          creditCardId: data['creditCardId'] as String?,
        );
      }).toList();
    });
  }

  Future<List<TransactionItem>> getExpenses(String userId) async {
    final querySnap = await _expensesCol(userId)
        .orderBy('date', descending: true)
        .get();
    return querySnap.docs.map((doc) {
      final data = doc.data();
      return TransactionItem(
        id: doc.id,
        userId: userId,
        title: data['title'] as String? ?? 'Gasto sin título',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        category: data['category'] as String? ?? 'Otros',
        date: _parseDateTime(data['date']),
        periodicity: data['periodicity'] as String? ?? 'único',
        paymentMethod: data['paymentMethod'] as String? ?? 'efectivo',
        creditCardId: data['creditCardId'] as String?,
      );
    }).toList();
  }

  Future<void> addExpense(TransactionItem expense) async {
    final docRef = expense.id.isNotEmpty
        ? _expensesCol(expense.userId).doc(expense.id)
        : _expensesCol(expense.userId).doc();

    await docRef.set({
      'id': docRef.id,
      'userId': expense.userId,
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'date': Timestamp.fromDate(expense.date),
      'periodicity': expense.periodicity,
      'paymentMethod': expense.paymentMethod,
      'creditCardId': expense.creditCardId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateExpense(TransactionItem expense) async {
    await _expensesCol(expense.userId).doc(expense.id).update({
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'date': Timestamp.fromDate(expense.date),
      'periodicity': expense.periodicity,
      'paymentMethod': expense.paymentMethod,
      'creditCardId': expense.creditCardId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _expensesCol(userId).doc(expenseId).delete();
  }

  // ==========================================
  // TARJETAS DE CRÉDITO (CREDIT_CARDS)
  // ==========================================

  Stream<List<CreditCard>> streamCreditCards(String userId) {
    return _cardsCol(userId).snapshots().map((querySnap) {
      return querySnap.docs.map((doc) {
        return CreditCard.fromFirestore(doc);
      }).toList();
    });
  }

  Future<List<CreditCard>> getCreditCards(String userId) async {
    final querySnap = await _cardsCol(userId).get();
    return querySnap.docs.map((doc) {
      return CreditCard.fromFirestore(doc);
    }).toList();
  }

  Future<void> addCreditCard(CreditCard card) async {
    final docRef = card.id.isNotEmpty
        ? _cardsCol(card.userId).doc(card.id)
        : _cardsCol(card.userId).doc();

    await docRef.set({
      'id': docRef.id,
      'userId': card.userId,
      'bankName': card.bankName,
      'cardName': card.cardName,
      'colorHex': card.colorHex,
      'cutOffDay': card.cutOffDay,
      'paymentDueDay': card.paymentDueDay,
      'creditLimit': card.creditLimit,
      'currentBalance': card.currentBalance,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCreditCard(CreditCard card) async {
    await _cardsCol(card.userId).doc(card.id).update({
      'bankName': card.bankName,
      'cardName': card.cardName,
      'colorHex': card.colorHex,
      'cutOffDay': card.cutOffDay,
      'paymentDueDay': card.paymentDueDay,
      'creditLimit': card.creditLimit,
      'currentBalance': card.currentBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCardBalance(String userId, String cardId, double newBalance) async {
    await _cardsCol(userId).doc(cardId).update({
      'currentBalance': newBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCreditCard(String userId, String cardId) async {
    await _cardsCol(userId).doc(cardId).delete();
  }

  // ==========================================
  // METAS DE AHORRO (SAVINGS_GOALS)
  // ==========================================

  Stream<List<SavingsGoal>> streamSavingsGoals(String userId) {
    return _goalsCol(userId).snapshots().map((querySnap) {
      return querySnap.docs.map((doc) {
        final data = doc.data();
        return SavingsGoal(
          id: doc.id,
          userId: userId,
          title: data['title'] as String? ?? 'Meta',
          targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 1000.0,
          currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
          targetDate: _parseDateTime(data['targetDate']),
          colorHex: data['colorHex'] as String? ?? '#2E5339',
        );
      }).toList();
    });
  }

  Future<List<SavingsGoal>> getSavingsGoals(String userId) async {
    final querySnap = await _goalsCol(userId).get();
    return querySnap.docs.map((doc) {
      final data = doc.data();
      return SavingsGoal(
        id: doc.id,
        userId: userId,
        title: data['title'] as String? ?? 'Meta',
        targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 1000.0,
        currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
        targetDate: _parseDateTime(data['targetDate']),
        colorHex: data['colorHex'] as String? ?? '#2E5339',
      );
    }).toList();
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    final docRef = goal.id.isNotEmpty
        ? _goalsCol(goal.userId).doc(goal.id)
        : _goalsCol(goal.userId).doc();

    await docRef.set({
      'id': docRef.id,
      'userId': goal.userId,
      'title': goal.title,
      'targetAmount': goal.targetAmount,
      'currentAmount': goal.currentAmount,
      'targetDate': Timestamp.fromDate(goal.targetDate),
      'colorHex': goal.colorHex,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _goalsCol(goal.userId).doc(goal.id).update({
      'title': goal.title,
      'targetAmount': goal.targetAmount,
      'currentAmount': goal.currentAmount,
      'targetDate': Timestamp.fromDate(goal.targetDate),
      'colorHex': goal.colorHex,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addContributionToGoal(String userId, String goalId, double additionalAmount) async {
    final docRef = _goalsCol(userId).doc(goalId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (snapshot.exists) {
        final current = (snapshot.data()?['currentAmount'] as num?)?.toDouble() ?? 0.0;
        tx.update(docRef, {
          'currentAmount': current + additionalAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> deleteSavingsGoal(String userId, String goalId) async {
    await _goalsCol(userId).doc(goalId).delete();
  }

  // ==========================================
  // POBLADO INICIAL EN LA NUBE SI ESTÁ VACÍO
  // ==========================================

  Future<void> seedInitialUserDataIfEmpty(
    String userId,
    String email,
    String name,
    double incomeAmount,
    String incomeType,
    String currency,
  ) async {
    final userSnap = await _userDoc(userId).get();
    if (!userSnap.exists) {
      final now = DateTime.now();
      final profile = UserProfile(
        id: userId,
        email: email,
        name: name.trim().isEmpty ? 'Usuario FinamaX' : name.trim(),
        currency: currency,
        incomeType: incomeType,
        incomeAmount: incomeAmount,
        nextPayDate: now.day <= 15
            ? DateTime(now.year, now.month, 15)
            : DateTime(now.year, now.month, 28),
      );
      await saveUserProfile(profile);

      // Seed cards
      await addCreditCard(CreditCard(
        id: 'card-nu-1',
        userId: userId,
        bankName: 'Nu Bank',
        cardName: 'Nu Gold Mastercard',
        colorHex: '#6E4B33',
        cutOffDay: 12,
        paymentDueDay: 2,
        creditLimit: 35000.0,
        currentBalance: 4250.0,
      ));

      await addCreditCard(CreditCard(
        id: 'card-bbva-2',
        userId: userId,
        bankName: 'BBVA',
        cardName: 'BBVA Oro Visa',
        colorHex: '#2E5339',
        cutOffDay: 24,
        paymentDueDay: 14,
        creditLimit: 60000.0,
        currentBalance: 8120.0,
      ));

      // Seed expenses
      await addExpense(TransactionItem(
        id: 'tx-1',
        userId: userId,
        title: 'Supermercado Semanal',
        amount: 2150.0,
        category: 'Alimentación',
        date: now.subtract(const Duration(days: 1)),
        periodicity: 'semanal',
        paymentMethod: 'debito',
      ));

      await addExpense(TransactionItem(
        id: 'tx-2',
        userId: userId,
        title: 'Gasolina y Transporte',
        amount: 850.0,
        category: 'Transporte',
        date: now.subtract(const Duration(hours: 18)),
        periodicity: 'semanal',
        paymentMethod: 'debito',
      ));

      await addExpense(TransactionItem(
        id: 'tx-3',
        userId: userId,
        title: 'Suscripciones y Cloud',
        amount: 399.0,
        category: 'Servicios',
        date: now.subtract(const Duration(days: 3)),
        periodicity: 'mensual',
        paymentMethod: 'tarjeta_credito',
        creditCardId: 'card-bbva-2',
      ));

      // Seed goals
      await addSavingsGoal(SavingsGoal(
        id: 'goal-1',
        userId: userId,
        title: 'Fondo de Emergencia (3 meses)',
        targetAmount: 50000.0,
        currentAmount: 28500.0,
        targetDate: now.add(const Duration(days: 120)),
        colorHex: '#2E5339',
      ));

      await addSavingsGoal(SavingsGoal(
        id: 'goal-2',
        userId: userId,
        title: 'Viaje a Japón 🇯🇵',
        targetAmount: 45000.0,
        currentAmount: 16000.0,
        targetDate: now.add(const Duration(days: 180)),
        colorHex: '#6E4B33',
      ));
    }
  }
}
