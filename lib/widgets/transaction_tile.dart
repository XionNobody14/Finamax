import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/transaction_item.dart';

/// Tile estilizado para mostrar transacciones en FinamaX con estética orgánica
class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final String? cardName;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.cardName,
    this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'alimentación':
      case 'comida':
        return Icons.restaurant;
      case 'transporte':
      case 'gasolina':
        return Icons.directions_car;
      case 'vivienda':
      case 'hogar':
        return Icons.home;
      case 'servicios':
        return Icons.receipt_long;
      case 'entretenimiento':
        return Icons.local_activity;
      case 'salud':
        return Icons.medical_services;
      case 'educación':
        return Icons.school;
      case 'ahorro':
        return Icons.savings;
      default:
        return Icons.shopping_bag;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'alimentación':
        return AppColors.warmAmber;
      case 'transporte':
        return AppColors.earthBrown;
      case 'vivienda':
        return const Color(0xFF4A6B82);
      case 'servicios':
        return AppColors.forestGreen;
      case 'ahorro':
        return AppColors.forestGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('dd MMM, hh:mm a');
    final iconColor = _getCategoryColor(transaction.category);

    String paymentLabel;
    if (transaction.paymentMethod == 'tarjeta_credito') {
      paymentLabel = cardName != null ? 'TDC • $cardName' : 'TDC';
    } else if (transaction.paymentMethod == 'debito') {
      paymentLabel = 'Débito';
    } else {
      paymentLabel = 'Efectivo';
    }

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.terracottaRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            // Icono de Categoría
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getCategoryIcon(transaction.category), color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Título, Fecha y Método de pago
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        dateFormatter.format(transaction.date),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          paymentLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Monto
            Text(
              '-${currencyFormatter.format(transaction.amount)}',
              style: const TextStyle(
                color: AppColors.terracottaRed,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
