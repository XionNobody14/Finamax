import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/credit_card.dart';

/// Widget visual interactivo de Tarjeta de Crédito realista con bordes orgánicos
class CreditCardWidget extends StatelessWidget {
  final CreditCard card;
  final bool isRecommendedToday;
  final VoidCallback? onTap;

  const CreditCardWidget({
    super.key,
    required this.card,
    this.isRecommendedToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final cardBaseColor = card.color;
    final daysUntilCut = card.getDaysUntilCutOff();
    final graceDays = card.getGracePeriodDaysIfUsedToday();
    final isUrgentCut = daysUntilCut <= 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        height: 195,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              cardBaseColor,
              cardBaseColor.withOpacity(0.85),
              const Color(0xFF1E2822),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isRecommendedToday
                  ? AppColors.forestGreen.withOpacity(0.35)
                  : cardBaseColor.withOpacity(0.25),
              blurRadius: isRecommendedToday ? 18 : 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isRecommendedToday ? AppColors.forestGreenLight : Colors.white.withOpacity(0.15),
            width: isRecommendedToday ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Patrón decorativo de fondo
              Positioned(
                right: -40,
                bottom: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header: Banco y Chip EMV
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            card.bankName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.wifi, color: Colors.white.withOpacity(0.7), size: 18),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black38, width: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Saldo Actual y Nombre
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.cardName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              currencyFormatter.format(card.currentBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '/ ${currencyFormatter.format(card.creditLimit)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Barra de utilización y Fechas de corte/pago
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: card.utilizationRatio,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              card.utilizationRatio > 0.8
                                  ? AppColors.terracottaRed
                                  : (card.utilizationRatio > 0.5 ? AppColors.warmAmber : const Color(0xFF68B281)),
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: isUrgentCut ? AppColors.warmAmber : Colors.white70,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Corta: día ${card.cutOffDay} ($daysUntilCut d)',
                                  style: TextStyle(
                                    color: isUrgentCut ? AppColors.warmAmber : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: isUrgentCut ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.payment, color: Colors.white70, size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  'Pagar: día ${card.paymentDueDay}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badge de Tarjeta Recomendada para hoy (45-50 días de gracia a 0%)
              if (isRecommendedToday)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B6E4A),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.white, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          'HOY: +$graceDays DÍAS A 0%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
