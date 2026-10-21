import 'dart:math';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/credit_card.dart';
import '../models/transaction_item.dart';
import '../models/savings_goal.dart';

/// Estado de salud presupuestal determinista
enum BudgetHealth {
  healthy,  // En meta: Margen holgado para cumplir ahorro y gastos
  tight,    // Ajustado: El margen diario es estrecho respecto al costo de vida
  exceeded, // Excedido: Gastos y compromisos superan los ingresos del ciclo
}

/// Informe de presupuesto y metas de ahorro generado matemáticamente
class SpendingBudgetReport {
  final BudgetHealth healthStatus;
  final String healthLabel;
  final double dailyBudgetSuggested;
  final double weeklyBudgetSuggested;
  final double realAvailableCycleBalance;
  final double totalCommittedSavingsInCycle;
  final String impactIndicator;
  final CreditCard? recommendedCard;
  final String creditCardAdvice;
  final List<String> actionableTips;

  const SpendingBudgetReport({
    required this.healthStatus,
    required this.healthLabel,
    required this.dailyBudgetSuggested,
    required this.weeklyBudgetSuggested,
    required this.realAvailableCycleBalance,
    required this.totalCommittedSavingsInCycle,
    required this.impactIndicator,
    this.recommendedCard,
    required this.creditCardAdvice,
    required this.actionableTips,
  });
}

/// Motor de Cálculo Presupuestal y Metas de Ahorro Determinista
/// 100% Local, sin dependencias de red ni LLMs externos.
class SpendingBudgetCalculator {
  /// Calcula el ahorro requerido por día para una meta específica:
  /// Ahorro Requerido por Día = (Monto Objetivo - Monto Actual) / Días Faltantes
  static double calculateDailySavingsRequired(SavingsGoal goal) {
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);
    if (remaining <= 0) return 0.0;
    final days = max(1, goal.daysRemaining);
    return remaining / days;
  }

  /// Calcula el presupuesto disponible y el límite de gasto diario permitido
  static SpendingBudgetReport calculateReport({
    required UserProfile profile,
    required List<CreditCard> cards,
    required List<TransactionItem> transactions,
    required List<SavingsGoal> goals,
    required double currentCycleExpenses,
    required int daysUntilNextPay,
  }) {
    final safeCycleDays = max(1, daysUntilNextPay);
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('dd/MM/yyyy');

    // 1. Ahorro Total Comprometido para el ciclo restante
    double totalDailySavingsNeeded = 0.0;
    SavingsGoal? primaryGoal;
    double maxRemainingAmount = -1;

    for (final goal in goals) {
      final dailyReq = calculateDailySavingsRequired(goal);
      totalDailySavingsNeeded += dailyReq;

      // Identificar la meta más prioritaria/relevante con monto faltante
      if (goal.remainingAmount > 0 && goal.remainingAmount > maxRemainingAmount) {
        maxRemainingAmount = goal.remainingAmount;
        primaryGoal = goal;
      }
    }

    final totalCommittedSavingsInCycle = totalDailySavingsNeeded * safeCycleDays;

    // 2. Saldo Real Disponible del Ciclo:
    // Ingreso del ciclo - Gastos ya realizados en el ciclo
    final realAvailableCycleBalance = profile.incomeAmount - currentCycleExpenses;

    // 3. Presupuesto Diario Sugerido (Límite Máximo de Gasto Permitido):
    // Presupuesto Diario = (Ingreso Disponible del Ciclo - Ahorro Comprometido) / Días Restantes
    final netFreeCycleMoney = realAvailableCycleBalance - totalCommittedSavingsInCycle;
    final dailyBudgetSuggested = (netFreeCycleMoney / safeCycleDays);
    final weeklyBudgetSuggested = dailyBudgetSuggested * 7;

    // 4. Determinación de Estado de Salud Presupuestal
    BudgetHealth healthStatus;
    String healthLabel;

    if (netFreeCycleMoney < 0 || dailyBudgetSuggested <= 0) {
      healthStatus = BudgetHealth.exceeded;
      healthLabel = 'Excedido';
    } else if (dailyBudgetSuggested < (profile.incomeAmount / (safeCycleDays * 4))) {
      // Si el disponible diario representa menos de un cuarto del promedio natural
      healthStatus = BudgetHealth.tight;
      healthLabel = 'Ajustado';
    } else {
      healthStatus = BudgetHealth.healthy;
      healthLabel = 'En meta';
    }

    // 5. Indicador de Impacto
    String impactIndicator;
    if (primaryGoal != null) {
      final dailyCeil = max(0.0, dailyBudgetSuggested);
      impactIndicator =
          'Si gastas menos de ${currencyFormatter.format(dailyCeil)} al día, alcanzarás tu meta de "${primaryGoal.title}" para el ${dateFormatter.format(primaryGoal.targetDate)}.';
    } else {
      impactIndicator =
          'Tus finanzas no tienen metas de ahorro comprometidas. Puedes destinar hasta ${currencyFormatter.format(max(0.0, dailyBudgetSuggested))} al día a nuevos proyectos.';
    }

    // 6. Reglas Inteligentes para Tarjetas de Crédito sin IA
    CreditCard? bestCard;
    int maxGrace = -1;

    for (final card in cards) {
      if (card.availableCredit <= 0) continue;
      final grace = card.getGracePeriodDaysIfUsedToday();
      if (grace > maxGrace) {
        maxGrace = grace;
        bestCard = card;
      }
    }

    String creditCardAdvice;
    if (bestCard != null) {
      final daysSinceCut = bestCard.getDaysSinceLastCutOff();
      creditCardAdvice =
          'Usa hoy tu tarjeta ${bestCard.bankName} (Corte hace $daysSinceCut días, ganas hasta $maxGrace días de financiamiento a tasa 0%).';
    } else if (cards.isNotEmpty) {
      creditCardAdvice = 'Revisa tus tarjetas: ninguna cuenta con saldo disponible actualmente.';
    } else {
      creditCardAdvice = 'No tienes tarjetas de crédito asociadas. Registra tus plásticos para maximizar días de financiamiento.';
    }

    // 7. Píldoras y Tips de Acción Concretos
    final tips = <String>[
      'Límite seguro hoy: ${currencyFormatter.format(max(0.0, dailyBudgetSuggested))}',
      if (bestCard != null) 'TDC óptima: ${bestCard.bankName} (+${bestCard.getGracePeriodDaysIfUsedToday()}d)',
      if (goals.isNotEmpty) 'Reserva de ahorro: ${currencyFormatter.format(totalCommittedSavingsInCycle)}',
    ];

    return SpendingBudgetReport(
      healthStatus: healthStatus,
      healthLabel: healthLabel,
      dailyBudgetSuggested: max(0.0, dailyBudgetSuggested),
      weeklyBudgetSuggested: max(0.0, weeklyBudgetSuggested),
      realAvailableCycleBalance: realAvailableCycleBalance,
      totalCommittedSavingsInCycle: totalCommittedSavingsInCycle,
      impactIndicator: impactIndicator,
      recommendedCard: bestCard,
      creditCardAdvice: creditCardAdvice,
      actionableTips: tips,
    );
  }

  /// Simulación Determinista de Impacto de Gasto
  static Map<String, dynamic> simulateExpenseImpact({
    required double amount,
    required String paymentMethod,
    required CreditCard? selectedCard,
    required double currentAvailableBalance,
    required double totalSavingsCommitted,
    required int daysUntilNextPay,
  }) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final safeDays = max(1, daysUntilNextPay);

    final balanceAfterExpense = currentAvailableBalance - amount;
    final netFreeAfter = balanceAfterExpense - totalSavingsCommitted;
    final newDailyBudget = (netFreeAfter / safeDays);
    final isRisky = netFreeAfter < 0;

    String message;
    String recommendation;

    if (paymentMethod == 'tarjeta_credito' && selectedCard != null) {
      final grace = selectedCard.getGracePeriodDaysIfUsedToday();
      final newBalance = selectedCard.currentBalance + amount;
      final ratio = selectedCard.creditLimit > 0 ? (newBalance / selectedCard.creditLimit) : 1.0;

      if (ratio > 0.8) {
        message = 'Atención: Este gasto elevará el uso de ${selectedCard.bankName} al ${(ratio * 100).toStringAsFixed(0)}% de tu límite.';
        recommendation = 'Procura liquidar saldo antes de la fecha límite (Día ${selectedCard.paymentDueDay}).';
      } else {
        message = 'Estrategia Óptima: Con ${selectedCard.bankName} ganas ~$grace días de crédito libre de intereses.';
        recommendation = 'Nuevo presupuesto diario proyectado: ${currencyFormatter.format(max(0.0, newDailyBudget))}';
      }
    } else {
      if (isRisky) {
        message = 'Riesgo Financiero: Este gasto compromete tu meta de ahorro por ${currencyFormatter.format(-netFreeAfter)}.';
        recommendation = 'Pospón esta compra o ajusta otra categoría para no caer en déficit.';
      } else {
        message = 'Gasto Viable: Mantienes cubierto tu ahorro comprometido.';
        recommendation = 'Tu nuevo límite de gasto diario será de ${currencyFormatter.format(newDailyBudget)} / día.';
      }
    }

    return {
      'remainingAfter': balanceAfterExpense,
      'netFreeAfter': netFreeAfter,
      'newDailyBudget': max(0.0, newDailyBudget),
      'isRisky': isRisky,
      'message': message,
      'recommendation': recommendation,
    };
  }
}
