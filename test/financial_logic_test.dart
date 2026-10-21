import 'package:flutter_test/flutter_test.dart';
import 'package:finamax/core/utils/date_calc_helper.dart';
import 'package:finamax/models/credit_card.dart';
import 'package:finamax/models/savings_goal.dart';
import 'package:finamax/models/user_profile.dart';
import 'package:finamax/services/spending_budget_calculator.dart';

void main() {
  group('DateCalcHelper & Leap Year Tests', () {
    test('Verifies leap year arithmetic accurately', () {
      expect(DateCalcHelper.isLeapYear(2024), isTrue); // Leap
      expect(DateCalcHelper.isLeapYear(2025), isFalse);
      expect(DateCalcHelper.isLeapYear(2026), isFalse);
      expect(DateCalcHelper.isLeapYear(2000), isTrue); // 400 divisible
      expect(DateCalcHelper.isLeapYear(1900), isFalse); // 100 but not 400
    });

    test('Verifies days in month correctly handles February in leap vs regular', () {
      expect(DateCalcHelper.daysInMonth(2024, 2), equals(29));
      expect(DateCalcHelper.daysInMonth(2026, 2), equals(28));
      expect(DateCalcHelper.daysInMonth(2026, 4), equals(30)); // April
      expect(DateCalcHelper.daysInMonth(2026, 12), equals(31)); // December
    });

    test('Safe date clamps invalid day 31 in February and April', () {
      final safeFeb = DateCalcHelper.safeDate(2026, 2, 31);
      expect(safeFeb.day, equals(28));

      final safeApr = DateCalcHelper.safeDate(2026, 4, 31);
      expect(safeApr.day, equals(30));
    });
  });

  group('CreditCard Grace Period & Cut-Off Optimization', () {
    test('Computes 45-50 days zero-interest grace when purchased immediately after cut-off', () {
      final reference = DateTime(2026, 3, 15);

      final cardA = CreditCard(
        id: 'card-a',
        userId: 'user-1',
        bankName: 'Nu Bank',
        cardName: 'Gold',
        cutOffDay: 14,
        paymentDueDay: 4,
        creditLimit: 30000,
        currentBalance: 0,
      );

      final cardB = CreditCard(
        id: 'card-b',
        userId: 'user-1',
        bankName: 'BBVA',
        cardName: 'Azul',
        cutOffDay: 16,
        paymentDueDay: 6,
        creditLimit: 30000,
        currentBalance: 0,
      );

      final graceA = cardA.getGracePeriodDaysIfUsedToday(reference);
      final graceB = cardB.getGracePeriodDaysIfUsedToday(reference);

      expect(graceA, greaterThan(graceB));
      expect(graceA, greaterThanOrEqualTo(45));
    });
  });

  group('SpendingBudgetCalculator Tests', () {
    test('Calculates exact daily savings and daily budget limit', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'g1',
        userId: 'u1',
        title: 'Fondo Emergencia',
        targetAmount: 6000,
        currentAmount: 3000,
        targetDate: now.add(const Duration(days: 30)),
      );

      // (6000 - 3000) / 30 = 100/día
      final dailySavings = SpendingBudgetCalculator.calculateDailySavingsRequired(goal);
      expect(dailySavings, closeTo(100.0, 5.0));

      final profile = UserProfile(
        id: 'u1',
        email: 'test@finamax.app',
        name: 'Andrea',
        incomeType: 'quincenal',
        incomeAmount: 15000,
        nextPayDate: now.add(const Duration(days: 15)),
      );

      final report = SpendingBudgetCalculator.calculateReport(
        profile: profile,
        cards: [],
        transactions: [],
        goals: [goal],
        currentCycleExpenses: 3000, // Gastado: 3,000
        daysUntilNextPay: 15, // Días restantes: 15
      );

      // Ingreso Ciclo: 15,000
      // Saldo disponible ciclo: 15,000 - 3,000 = 12,000
      // Ahorro requerido ciclo (15 días * ~100/día) = ~1,500
      // Dinero libre neto: 12,000 - 1,500 = 10,500
      // Presupuesto diario sugerido: 10,500 / 15 = ~700/día
      expect(report.healthStatus, equals(BudgetHealth.healthy));
      expect(report.dailyBudgetSuggested, closeTo(700.0, 50.0));
      expect(report.impactIndicator, contains('Fondo Emergencia'));
    });

    test('Identifies exceeded budget when expenses exceed cycle income', () {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'u1',
        email: 'test@finamax.app',
        name: 'Andrea',
        incomeType: 'quincenal',
        incomeAmount: 10000,
        nextPayDate: now.add(const Duration(days: 10)),
      );

      final report = SpendingBudgetCalculator.calculateReport(
        profile: profile,
        cards: [],
        transactions: [],
        goals: [],
        currentCycleExpenses: 12000, // Excedido en 2000
        daysUntilNextPay: 10,
      );

      expect(report.healthStatus, equals(BudgetHealth.exceeded));
      expect(report.dailyBudgetSuggested, equals(0.0));
    });
  });
}
