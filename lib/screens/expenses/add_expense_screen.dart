import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/transaction_item.dart';
import '../../models/credit_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/spending_budget_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _category = 'Alimentación';
  String _paymentMethod = 'debito'; // 'efectivo', 'debito', 'tarjeta_credito'
  String? _selectedCreditCardId;
  String _periodicity = 'único';
  final DateTime _date = DateTime.now();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Alimentación', 'icon': Icons.restaurant, 'color': AppColors.warmAmber},
    {'name': 'Transporte', 'icon': Icons.directions_car, 'color': AppColors.earthBrown},
    {'name': 'Vivienda', 'icon': Icons.home, 'color': const Color(0xFF4A6B82)},
    {'name': 'Servicios', 'icon': Icons.receipt_long, 'color': AppColors.forestGreen},
    {'name': 'Entretenimiento', 'icon': Icons.local_activity, 'color': const Color(0xFF9E5778)},
    {'name': 'Salud', 'icon': Icons.medical_services, 'color': const Color(0xFF3B8263)},
    {'name': 'Educación', 'icon': Icons.school, 'color': const Color(0xFF8B5E3C)},
    {'name': 'Otros', 'icon': Icons.shopping_bag, 'color': AppColors.textSecondary},
  ];

  @override
  void initState() {
    super.initState();
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    if (finance.cards.isNotEmpty) {
      _selectedCreditCardId = finance.bestCardForToday?.id ?? finance.cards.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);

    final expense = TransactionItem(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      userId: auth.currentUser?.id ?? 'user',
      title: _titleController.text.trim(),
      amount: amount,
      category: _category,
      date: _date,
      periodicity: _periodicity,
      paymentMethod: _paymentMethod,
      creditCardId: _paymentMethod == 'tarjeta_credito' ? _selectedCreditCardId : null,
    );

    finance.addExpense(expense);
    budget.updateReport(finance);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    CreditCard? currentCard;
    if (_selectedCreditCardId != null && finance.cards.isNotEmpty) {
      currentCard = finance.cards.firstWhere(
        (c) => c.id == _selectedCreditCardId,
        orElse: () => finance.cards.first,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Gasto'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Destacado de Monto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MONTO DEL GASTO',
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
                        autofocus: true,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(
                            color: AppColors.terracottaRed,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                          hintText: '0.00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                          final num = double.tryParse(v);
                          if (num == null || num <= 0) return 'Monto inválido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Concepto / Título
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    labelText: 'Concepto (ej. Despensa, Farmacia, Transporte)',
                    prefixIcon: Icon(Icons.edit_note, color: AppColors.forestGreen),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el concepto' : null,
                ),
                const SizedBox(height: 20),

                // Selector de Categoría
                const Text(
                  'Categoría',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final name = cat['name'] as String;
                    final icon = cat['icon'] as IconData;
                    final color = cat['color'] as Color;
                    final isSelected = _category == name;

                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: isSelected ? Colors.white : color),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      backgroundColor: AppColors.surfaceCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isSelected ? color : AppColors.border),
                      ),
                      onSelected: (_) => setState(() => _category = name),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Selector de Método de Pago
                const Text(
                  'Método de Pago',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildMethodOption('debito', 'Débito', Icons.account_balance),
                    const SizedBox(width: 10),
                    _buildMethodOption('tarjeta_credito', 'Crédito', Icons.credit_card),
                    const SizedBox(width: 10),
                    _buildMethodOption('efectivo', 'Efectivo', Icons.payments_outlined),
                  ],
                ),
                const SizedBox(height: 14),

                // Si seleccionó Tarjeta de Crédito, mostrar dropdown y análisis de corte
                if (_paymentMethod == 'tarjeta_credito') ...[
                  if (finance.cards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warmAmberMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warmAmber.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'No tienes tarjetas registradas. Agrega una en la pestaña de Tarjetas.',
                        style: TextStyle(color: AppColors.warmAmber, fontSize: 12),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      value: _selectedCreditCardId,
                      dropdownColor: AppColors.surfaceCard,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Seleccionar Tarjeta de Crédito'),
                      items: finance.cards.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.bankName} - ${c.cardName}'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCreditCardId = v),
                    ),
                    const SizedBox(height: 10),

                    if (currentCard != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.forestGreen, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Corta en ${currentCard.getDaysUntilCutOff()} días. Al pagar hoy obtienes ~${currentCard.getGracePeriodDaysIfUsedToday()} días libres de intereses hasta el pago.',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                ],

                // Selector de Periodicidad
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _periodicity,
                        dropdownColor: AppColors.surfaceCard,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(labelText: 'Frecuencia'),
                        items: const [
                          DropdownMenuItem(value: 'único', child: Text('Gasto Único')),
                          DropdownMenuItem(value: 'diario', child: Text('Diario Recurrente')),
                          DropdownMenuItem(value: 'semanal', child: Text('Semanal Recurrente')),
                          DropdownMenuItem(value: 'quincenal', child: Text('Quincenal')),
                          DropdownMenuItem(value: 'mensual', child: Text('Mensual Fijo')),
                        ],
                        onChanged: (v) => setState(() => _periodicity = v ?? 'único'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Registrar Gasto'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption(String method, String label, IconData icon) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
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
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.forestGreen : AppColors.textSecondary, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
