/// Modelo de Transacción / Gasto en FinamaX
class TransactionItem {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category; // 'Alimentación', 'Transporte', 'Vivienda', 'Servicios', 'Entretenimiento', 'Salud', 'Educación', 'Otros'
  final DateTime date;
  final String periodicity; // 'diario' | 'semanal' | 'mensual' | 'único'
  final String paymentMethod; // 'efectivo' | 'debito' | 'tarjeta_credito'
  final String? creditCardId; // Opcional si se pagó con tarjeta

  TransactionItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.periodicity = 'único',
    required this.paymentMethod,
    this.creditCardId,
  });

  bool get isCreditCard => paymentMethod == 'tarjeta_credito';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'periodicity': periodicity,
      'paymentMethod': paymentMethod,
      'creditCardId': creditCardId,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String? ?? 'Otros',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      periodicity: json['periodicity'] as String? ?? 'único',
      paymentMethod: json['paymentMethod'] as String? ?? 'efectivo',
      creditCardId: json['creditCardId'] as String?,
    );
  }

  TransactionItem copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? periodicity,
    String? paymentMethod,
    String? creditCardId,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      periodicity: periodicity ?? this.periodicity,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      creditCardId: creditCardId ?? this.creditCardId,
    );
  }
}
