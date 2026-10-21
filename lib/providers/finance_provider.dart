import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';
import '../models/savings_goal.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

/// Proveedor Principal de Lógica y Métricas Financieras de FinamaX
/// Sincronizado en tiempo real con Cloud Firestore y respaldo local en StorageService
class FinanceProvider extends ChangeNotifier {
  final StorageService _storageService;
  final FirestoreService _firestoreService;

  UserProfile? _profile;
  List<CreditCard> _cards = [];
  List<TransactionItem> _transactions = [];
  List<SavingsGoal> _goals = [];
  bool _isLoading = true;

  StreamSubscription<List<CreditCard>>? _cardsSubscription;

  FinanceProvider({
    required StorageService storageService,
    required FirestoreService firestoreService,
  })  : _storageService = storageService,
        _firestoreService = firestoreService;

  // Getters
  UserProfile? get profile => _profile;
  List<CreditCard> get cards => List.unmodifiable(_cards);
  List<TransactionItem> get transactions => List.unmodifiable(_transactions);
  List<SavingsGoal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;
  FirestoreService get firestoreService => _firestoreService;

  /// Permite actualizar la lista de tarjetas desde un Stream en tiempo real
  void updateCardsFromStream(List<CreditCard> liveCards) {
    _cards = liveCards;
    _storageService.saveCreditCards(liveCards);
    notifyListeners();
  }

  /// Inicializa cargando todos los datos del usuario actual desde Firestore y local
  Future<void> loadData(UserProfile userProfile) async {
    _isLoading = true;
    _profile = userProfile;
    notifyListeners();

    try {
      // 1. Suscribirse al stream en tiempo real de tarjetas de crédito
      _cardsSubscription?.cancel();
      _cardsSubscription = _firestoreService.streamCreditCards(userProfile.id).listen((liveCards) {
        _cards = liveCards;
        _storageService.saveCreditCards(liveCards);
        notifyListeners();
      });

      // 2. Carga y sincronización independiente de Tarjetas
      final firestoreCards = await _firestoreService.getCreditCards(userProfile.id);
      if (firestoreCards.isNotEmpty) {
        _cards = firestoreCards;
        await _storageService.saveCreditCards(_cards);
      } else {
        final localCards = await _storageService.getCreditCards();
        if (localCards.isNotEmpty) {
          _cards = localCards;
          for (final card in _cards) {
            await _firestoreService.addCreditCard(card.copyWith(userId: userProfile.id));
          }
        }
      }

      // 3. Carga y sincronización independiente de Gastos
      final firestoreTx = await _firestoreService.getExpenses(userProfile.id);
      if (firestoreTx.isNotEmpty) {
        _transactions = firestoreTx;
        await _storageService.saveTransactions(_transactions);
      } else {
        final localTx = await _storageService.getTransactions();
        if (localTx.isNotEmpty) {
          _transactions = localTx;
          for (final tx in _transactions) {
            await _firestoreService.addExpense(tx.copyWith(userId: userProfile.id));
          }
        }
      }

      // 4. Carga y sincronización independiente de Metas
      final firestoreGoals = await _firestoreService.getSavingsGoals(userProfile.id);
      if (firestoreGoals.isNotEmpty) {
        _goals = firestoreGoals;
        await _storageService.saveSavingsGoals(_goals);
      } else {
        final localGoals = await _storageService.getSavingsGoals();
        if (localGoals.isNotEmpty) {
          _goals = localGoals;
          for (final goal in _goals) {
            await _firestoreService.addSavingsGoal(goal.copyWith(userId: userProfile.id));
          }
        }
      }

      // Ordenar transacciones por fecha descendente
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      // Fallback a almacenamiento local en caso de excepción de red
      _cards = await _storageService.getCreditCards();
      _transactions = await _storageService.getTransactions();
      _goals = await _storageService.getSavingsGoals();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // CÁLCULOS DE INGRESOS Y CICLOS
  // ==========================================

  /// Ingreso base del ciclo configurado
  double get cycleIncome {
    if (_profile == null) return 0.0;
    return _profile!.incomeAmount;
  }

  /// Días restantes para el próximo pago de nómina
  int get daysUntilNextPay {
    if (_profile == null) return 15;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var payDate = DateTime(_profile!.nextPayDate.year, _profile!.nextPayDate.month, _profile!.nextPayDate.day);

    if (payDate.isBefore(today)) {
      final daysToAdd = _profile!.incomeType.toLowerCase() == 'quincenal' ? 15 : 30;
      payDate = payDate.add(Duration(days: daysToAdd));
    }

    return max(1, payDate.difference(today).inDays);
  }

  // ==========================================
  // DESGLOSE TEMPORAL DE GASTOS
  // ==========================================

  List<TransactionItem> get transactionsToday {
    final now = DateTime.now();
    return _transactions.where((tx) {
      return tx.date.year == now.year &&
          tx.date.month == now.month &&
          tx.date.day == now.day;
    }).toList();
  }

  double get totalExpensesToday {
    return transactionsToday.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  List<TransactionItem> get transactionsThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _transactions.where((tx) {
      return !tx.date.isBefore(startDate);
    }).toList();
  }

  double get totalExpensesThisWeek {
    return transactionsThisWeek.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  List<TransactionItem> get transactionsThisMonth {
    final now = DateTime.now();
    return _transactions.where((tx) {
      return tx.date.year == now.year && tx.date.month == now.month;
    }).toList();
  }

  double get totalExpensesThisMonth {
    return transactionsThisMonth.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get currentCycleExpenses {
    if (_profile?.incomeType.toLowerCase() == 'quincenal') {
      final now = DateTime.now();
      final cycleStart = now.day <= 15
          ? DateTime(now.year, now.month, 1)
          : DateTime(now.year, now.month, 16);
      return _transactions
          .where((tx) => !tx.date.isBefore(cycleStart))
          .fold(0.0, (sum, tx) => sum + tx.amount);
    } else {
      return totalExpensesThisMonth;
    }
  }

  // ==========================================
  // COMPROMISOS Y SALDO NETO DISPONIBLE
  // ==========================================

  double get totalCreditCardsBalance {
    return _cards.fold(0.0, (sum, c) => sum + c.currentBalance);
  }

  double get totalCreditAvailable {
    return _cards.fold(0.0, (sum, c) => sum + c.availableCredit);
  }

  double get requiredCycleSavingsContribution {
    final isQuincenal = _profile?.incomeType.toLowerCase() == 'quincenal';
    return _goals.fold(0.0, (sum, g) {
      return sum + (isQuincenal ? g.quincenalRequiredContribution : g.monthlyRequiredContribution);
    });
  }

  double get netAvailableBalance {
    final balance = cycleIncome - currentCycleExpenses - requiredCycleSavingsContribution;
    return balance;
  }

  double get suggestedDailyBudget {
    final days = daysUntilNextPay;
    return (netAvailableBalance / days).clamp(0.0, double.infinity);
  }

  CreditCard? get bestCardForToday {
    if (_cards.isEmpty) return null;
    CreditCard? best;
    int maxGrace = -1;

    for (final card in _cards) {
      if (card.availableCredit <= 0) continue;
      final grace = card.getGracePeriodDaysIfUsedToday();
      if (grace > maxGrace) {
        maxGrace = grace;
        best = card;
      }
    }

    return best ?? _cards.first;
  }

  // ==========================================
  // OPERACIONES CRUD REACTIVAS EN FIRESTORE
  // ==========================================

  Future<void> addExpense(TransactionItem expense) async {
    _transactions.insert(0, expense);

    // Si se pagó con tarjeta de crédito, actualizar el saldo de la tarjeta
    if (expense.isCreditCard && expense.creditCardId != null) {
      final index = _cards.indexWhere((c) => c.id == expense.creditCardId);
      if (index != -1) {
        final card = _cards[index];
        final updatedCard = card.copyWith(currentBalance: card.currentBalance + expense.amount);
        _cards[index] = updatedCard;
        await _storageService.saveCreditCards(_cards);
        await _firestoreService.updateCardBalance(card.userId, card.id, updatedCard.currentBalance);
      }
    }

    await _storageService.saveTransactions(_transactions);
    await _firestoreService.addExpense(expense);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index != -1) {
      final tx = _transactions[index];
      if (tx.isCreditCard && tx.creditCardId != null) {
        final cardIndex = _cards.indexWhere((c) => c.id == tx.creditCardId);
        if (cardIndex != -1) {
          final card = _cards[cardIndex];
          final newBal = max(0.0, card.currentBalance - tx.amount);
          final updatedCard = card.copyWith(currentBalance: newBal);
          _cards[cardIndex] = updatedCard;
          await _storageService.saveCreditCards(_cards);
          await _firestoreService.updateCardBalance(card.userId, card.id, newBal);
        }
      }
      _transactions.removeAt(index);
      await _storageService.saveTransactions(_transactions);
      await _firestoreService.deleteExpense(tx.userId, id);
      notifyListeners();
    }
  }

  Future<void> addCreditCard(CreditCard card) async {
    final existingIndex = _cards.indexWhere((c) => c.id == card.id);
    if (existingIndex != -1) {
      _cards[existingIndex] = card;
    } else {
      _cards.add(card);
    }
    await _storageService.saveCreditCards(_cards);
    await _firestoreService.addCreditCard(card);
    notifyListeners();
  }

  Future<void> updateCreditCard(CreditCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      _cards[index] = card;
    } else {
      _cards.add(card);
    }
    await _storageService.saveCreditCards(_cards);
    await _firestoreService.updateCreditCard(card);
    notifyListeners();
  }

  Future<void> deleteCreditCard(String id) async {
    final index = _cards.indexWhere((c) => c.id == id);
    String userId = _profile?.id ?? '';
    if (index != -1) {
      if (userId.isEmpty) {
        userId = _cards[index].userId;
      }
      _cards.removeAt(index);
    }
    await _storageService.saveCreditCards(_cards);
    if (userId.isNotEmpty) {
      await _firestoreService.deleteCreditCard(userId, id);
    }
    notifyListeners();
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    _goals.add(goal);
    await _storageService.saveSavingsGoals(_goals);
    await _firestoreService.addSavingsGoal(goal);
    notifyListeners();
  }

  Future<void> depositToSavingsGoal(String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _goals[index];
      final updatedGoal = goal.copyWith(currentAmount: goal.currentAmount + amount);
      _goals[index] = updatedGoal;
      await _storageService.saveSavingsGoals(_goals);
      await _firestoreService.addContributionToGoal(goal.userId, goalId, amount);

      // Registrar también como transacción de ahorro
      final now = DateTime.now();
      final tx = TransactionItem(
        id: 'goal-dep-${now.millisecondsSinceEpoch}',
        userId: _profile?.id ?? goal.userId,
        title: 'Abono: ${goal.title}',
        amount: amount,
        category: 'Ahorro',
        date: now,
        periodicity: 'único',
        paymentMethod: 'debito',
      );
      _transactions.insert(0, tx);
      await _storageService.saveTransactions(_transactions);
      await _firestoreService.addExpense(tx);

      notifyListeners();
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    final userId = _profile?.id ?? '';
    _goals.removeWhere((g) => g.id == id);
    await _storageService.saveSavingsGoals(_goals);
    if (userId.isNotEmpty) {
      await _firestoreService.deleteSavingsGoal(userId, id);
    }
    notifyListeners();
  }
}
