import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../services/spending_budget_calculator.dart';
import 'finance_provider.dart';

/// Proveedor de Estado del Presupuesto y Metas de Ahorro
/// Reemplaza completamente a los servicios de IA con un motor matemático determinista local.
class SpendingBudgetProvider extends ChangeNotifier {
  SpendingBudgetReport? _currentReport;

  SpendingBudgetReport? get currentReport => _currentReport;

  /// Recalcula el reporte presupuestal usando la lógica matemática local
  void updateReport(FinanceProvider finance) {
    if (finance.profile == null) return;

    _currentReport = SpendingBudgetCalculator.calculateReport(
      profile: finance.profile!,
      cards: finance.cards,
      transactions: finance.transactions,
      goals: finance.goals,
      currentCycleExpenses: finance.currentCycleExpenses,
      daysUntilNextPay: finance.daysUntilNextPay,
    );
    notifyListeners();
  }

  /// Simula el impacto de un gasto de forma determinista
  Map<String, dynamic> simulateExpense({
    required double amount,
    required String paymentMethod,
    required CreditCard? selectedCard,
    required FinanceProvider finance,
  }) {
    final report = _currentReport ??
        SpendingBudgetCalculator.calculateReport(
          profile: finance.profile!,
          cards: finance.cards,
          transactions: finance.transactions,
          goals: finance.goals,
          currentCycleExpenses: finance.currentCycleExpenses,
          daysUntilNextPay: finance.daysUntilNextPay,
        );

    return SpendingBudgetCalculator.simulateExpenseImpact(
      amount: amount,
      paymentMethod: paymentMethod,
      selectedCard: selectedCard,
      currentAvailableBalance: report.realAvailableCycleBalance,
      totalSavingsCommitted: report.totalCommittedSavingsInCycle,
      daysUntilNextPay: finance.daysUntilNextPay,
    );
  }
}
