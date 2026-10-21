import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/credit_card.dart';
import '../../providers/finance_provider.dart';
import '../../providers/spending_budget_provider.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final _amountController = TextEditingController(text: '1500');
  String _paymentMethod = 'tarjeta_credito';
  String? _selectedCardId;
  Map<String, dynamic>? _simulationResult;

  @override
  void initState() {
    super.initState();
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    if (finance.cards.isNotEmpty) {
      _selectedCardId = finance.bestCardForToday?.id ?? finance.cards.first.id;
    }
    _runSimulation();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _runSimulation() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);

    CreditCard? card;
    if (_paymentMethod == 'tarjeta_credito' && _selectedCardId != null && finance.cards.isNotEmpty) {
      card = finance.cards.firstWhere(
        (c) => c.id == _selectedCardId,
        orElse: () => finance.cards.first,
      );
    }

    setState(() {
      _simulationResult = budget.simulateExpense(
        amount: amount,
        paymentMethod: _paymentMethod,
        selectedCard: card,
        finance: finance,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    CreditCard? currentCard;
    if (_selectedCardId != null && finance.cards.isNotEmpty) {
      currentCard = finance.cards.firstWhere(
        (c) => c.id == _selectedCardId,
        orElse: () => finance.cards.first,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Simulador de Presupuesto'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calculate_outlined, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Cómo afecta esta compra mi meta?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Calcula matemáticamente el impacto en tu ahorro y el nuevo límite diario de gasto antes de pagar.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Input de Monto a Simular
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MONTO DE COMPRA ESTIMADA',
                      style: TextStyle(
                        color: AppColors.earthBrown,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '\$ ',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (_) => _runSimulation(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Método de Pago
              Row(
                children: [
                  _buildPaymentTab('tarjeta_credito', 'Tarjeta Crédito', Icons.credit_card),
                  const SizedBox(width: 8),
                  _buildPaymentTab('debito', 'Débito / Cash', Icons.account_balance_wallet),
                ],
              ),
              const SizedBox(height: 14),

              // Si es tarjeta de crédito
              if (_paymentMethod == 'tarjeta_credito' && finance.cards.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedCardId,
                  dropdownColor: AppColors.surfaceCard,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Tarjeta a Utilizar'),
                  items: finance.cards.map((c) {
                    final grace = c.getGracePeriodDaysIfUsedToday();
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.bankName} (${c.cardName}) - $grace días a 0%'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => _selectedCardId = v);
                    _runSimulation();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Dictamen de Simulación
              if (_simulationResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _simulationResult!['isRisky'] ? AppColors.terracottaRed : AppColors.forestGreen,
                      width: 1.5,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EVALUACIÓN MATEMÁTICA',
                            style: TextStyle(
                              color: AppColors.earthBrown,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _simulationResult!['isRisky']
                                  ? AppColors.terracottaMuted
                                  : AppColors.forestGreenMuted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _simulationResult!['isRisky'] ? 'ALTO RIESGO' : 'VIABLE',
                              style: TextStyle(
                                color: _simulationResult!['isRisky']
                                    ? AppColors.terracottaRed
                                    : AppColors.forestGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _simulationResult!['message'],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _simulationResult!['recommendation'],
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildResultMetric(
                            'Dinero Libre Post-Gasto',
                            currencyFormatter.format(_simulationResult!['netFreeAfter']),
                            _simulationResult!['netFreeAfter'] >= 0 ? AppColors.forestGreen : AppColors.terracottaRed,
                          ),
                          _buildResultMetric(
                            'Nuevo Tope Diario',
                            currencyFormatter.format(_simulationResult!['newDailyBudget']),
                            AppColors.earthBrown,
                          ),
                        ],
                      ),

                      if (currentCard != null && _paymentMethod == 'tarjeta_credito') ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, color: AppColors.warmAmber, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Corte: Día ${currentCard.cutOffDay} • Fecha Límite de Pago: Día ${currentCard.paymentDueDay}. Ganarías ~${currentCard.getGracePeriodDaysIfUsedToday()} días libres de intereses.',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTab(String method, String label, IconData icon) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _paymentMethod = method);
          _runSimulation();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceCard : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.forestGreen : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected ? AppColors.softShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppColors.forestGreen : AppColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
