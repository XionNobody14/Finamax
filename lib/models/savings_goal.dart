import 'dart:math';

/// Modelo de Meta de Ahorro en FinamaX
class SavingsGoal {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String colorHex;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.colorHex = '#10B981',
  });

  /// Progreso en escala 0.0 a 1.0
  double get progressRatio => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Porcentaje entero (0 a 100)
  int get progressPercent => (progressRatio * 100).toInt();

  /// Monto faltante para alcanzar la meta
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Días restantes hasta la fecha límite
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return max(0, target.difference(today).inDays);
  }

  /// Aportación diaria requerida para alcanzar la meta a tiempo
  double get dailyRequiredContribution {
    final days = max(1, daysRemaining);
    return remainingAmount / days;
  }

  /// Aportación quincenal requerida (15 días)
  double get quincenalRequiredContribution {
    return dailyRequiredContribution * 15;
  }

  /// Aportación mensual requerida (30 días)
  double get monthlyRequiredContribution {
    return dailyRequiredContribution * 30;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'colorHex': colorHex,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.tryParse(json['targetDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 90)),
      colorHex: json['colorHex'] as String? ?? '#10B981',
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? colorHex,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
