/// Perfil del usuario en FinamaX
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String currency; // 'MXN', 'USD', 'EUR', etc.
  final String incomeType; // 'quincenal' | 'mensual'
  final double incomeAmount;
  final DateTime nextPayDate;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.currency = 'MXN',
    this.incomeType = 'quincenal',
    required this.incomeAmount,
    required this.nextPayDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calcula el ingreso mensual equivalente
  double get monthlyEquivalentIncome {
    if (incomeType.toLowerCase() == 'quincenal') {
      return incomeAmount * 2;
    }
    return incomeAmount;
  }

  /// Calcula el ingreso por quincena
  double get quincenalIncome {
    if (incomeType.toLowerCase() == 'quincenal') {
      return incomeAmount;
    }
    return incomeAmount / 2;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'currency': currency,
      'incomeType': incomeType,
      'incomeAmount': incomeAmount,
      'nextPayDate': nextPayDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? 'Usuario FinamaX',
      currency: json['currency'] as String? ?? 'MXN',
      incomeType: json['incomeType'] as String? ?? 'quincenal',
      incomeAmount: (json['incomeAmount'] as num).toDouble(),
      nextPayDate: DateTime.tryParse(json['nextPayDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? currency,
    String? incomeType,
    double? incomeAmount,
    DateTime? nextPayDate,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      incomeType: incomeType ?? this.incomeType,
      incomeAmount: incomeAmount ?? this.incomeAmount,
      nextPayDate: nextPayDate ?? this.nextPayDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
