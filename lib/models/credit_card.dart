import 'package:flutter/material.dart';
import '../core/utils/date_calc_helper.dart';

/// Modelo de Tarjeta de Crédito en FinamaX
class CreditCard {
  final String id;
  final String userId;
  final String bankName;
  final String cardName;
  final String colorHex;
  final int cutOffDay; // 1 - 31
  final int paymentDueDay; // 1 - 31
  final double creditLimit;
  final double currentBalance;

  CreditCard({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.cardName,
    this.colorHex = '#2E5339',
    required this.cutOffDay,
    required this.paymentDueDay,
    required this.creditLimit,
    this.currentBalance = 0.0,
  });

  /// Color seguro obtenido a partir de colorHex sin lanzar excepciones
  Color get color {
    try {
      final clean = colorHex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF2E5339);
  }

  /// Saldo disponible en la línea de crédito
  double get availableCredit => (creditLimit - currentBalance).clamp(0.0, creditLimit);

  /// Porcentaje de uso de la tarjeta (0.0 a 1.0)
  double get utilizationRatio => creditLimit > 0 ? (currentBalance / creditLimit).clamp(0.0, 1.0) : 0.0;

  /// Próxima fecha de corte a partir de una fecha de referencia
  DateTime getNextCutOffDate([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    return DateCalcHelper.getNextOccurrenceOfDay(cutOffDay, ref);
  }

  /// Fecha del corte más reciente ocurrido
  DateTime getLastCutOffDate([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    return DateCalcHelper.getPreviousOccurrenceOfDay(cutOffDay, ref);
  }

  /// Próxima fecha límite de pago
  DateTime getNextPaymentDueDate([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final nextCut = getNextCutOffDate(ref);
    // La fecha de pago suele ocurrir 20 días después del corte o en paymentDueDay
    return DateCalcHelper.getNextOccurrenceOfDay(paymentDueDay, nextCut);
  }

  /// Días restantes para el próximo corte
  int getDaysUntilCutOff([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final nextCut = getNextCutOffDate(ref);
    return DateCalcHelper.daysUntil(nextCut, ref);
  }

  /// Días transcurridos desde el último corte
  int getDaysSinceLastCutOff([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final lastCut = getLastCutOffDate(ref);
    return DateCalcHelper.daysUntil(ref, lastCut);
  }

  /// Días de financiamiento sin intereses aproximados si se compra HOY
  /// Estrategia: Si compras justo el día después del corte, ganas ~45-50 días hasta el pago.
  int getGracePeriodDaysIfUsedToday([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    // Fecha de corte que cerrará las compras hechas hoy:
    // Si hoy es el mismo día de corte o antes, cerrará en el próximo corte.
    // Si hoy es 1 día después del corte, cerrará en el corte del siguiente mes.
    DateTime applicableCutOff;
    final daysSince = getDaysSinceLastCutOff(ref);

    if (daysSince == 0) {
      // Hoy es corte: compras por la tarde podrían entrar al siguiente mes o al actual
      applicableCutOff = getNextCutOffDate(ref.add(const Duration(days: 1)));
    } else {
      applicableCutOff = getNextCutOffDate(ref);
    }

    final dueDate = DateCalcHelper.getNextOccurrenceOfDay(paymentDueDay, applicableCutOff);
    final diff = DateCalcHelper.daysUntil(dueDate, ref);
    return diff.clamp(15, 55);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bankName': bankName,
      'cardName': cardName,
      'colorHex': colorHex,
      'cutOffDay': cutOffDay,
      'paymentDueDay': paymentDueDay,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
    };
  }

  factory CreditCard.fromFirestore(dynamic doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CreditCard.fromMap(data, docId: doc.id);
  }

  factory CreditCard.fromMap(Map<String, dynamic> data, {String? docId}) {
    return CreditCard(
      id: docId ?? (data['id'] as String? ?? ''),
      userId: data['userId'] as String? ?? '',
      bankName: data['bankName'] as String? ?? 'Banco',
      cardName: data['cardName'] as String? ?? 'Tarjeta',
      colorHex: data['colorHex'] as String? ?? '#2E5339',
      cutOffDay: (data['cutOffDay'] as num?)?.toInt() ??
          (int.tryParse(data['cutOffDay']?.toString() ?? '') ?? 15),
      paymentDueDay: (data['paymentDueDay'] as num?)?.toInt() ??
          (int.tryParse(data['paymentDueDay']?.toString() ?? '') ?? 5),
      creditLimit: (data['creditLimit'] as num?)?.toDouble() ??
          (double.tryParse(data['creditLimit']?.toString() ?? '') ?? 10000.0),
      currentBalance: (data['currentBalance'] as num?)?.toDouble() ??
          (double.tryParse(data['currentBalance']?.toString() ?? '') ?? 0.0),
    );
  }

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard.fromMap(json);
  }

  CreditCard copyWith({
    String? id,
    String? userId,
    String? bankName,
    String? cardName,
    String? colorHex,
    int? cutOffDay,
    int? paymentDueDay,
    double? creditLimit,
    double? currentBalance,
  }) {
    return CreditCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankName: bankName ?? this.bankName,
      cardName: cardName ?? this.cardName,
      colorHex: colorHex ?? this.colorHex,
      cutOffDay: cutOffDay ?? this.cutOffDay,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
