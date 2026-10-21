import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/savings_goal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/spending_budget_provider.dart';
import '../../widgets/savings_goal_card.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  void _showAddGoalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddGoalModal(),
    );
  }

  void _showDepositModal(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepositModal(goal: goal),
    );
  }

  void _confirmDeleteGoal(BuildContext context, SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Eliminar Meta', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Deseas eliminar la meta "${goal.title}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracottaRed),
            onPressed: () {
              final finance = Provider.of<FinanceProvider>(context, listen: false);
              final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);
              finance.deleteSavingsGoal(goal.id);
              budget.updateReport(finance);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final totalSaved = finance.goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final totalTarget = finance.goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final globalRatio = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metas de Ahorro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.forestGreen),
            tooltip: 'Nueva Meta',
            onPressed: () => _showAddGoalModal(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta Resumen de Metas
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.2),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FONDO TOTAL ACUMULADO',
                          style: TextStyle(
                            color: AppColors.forestGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreenMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(globalRatio * 100).toStringAsFixed(0)}% del objetivo',
                            style: const TextStyle(
                              color: AppColors.forestGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(totalSaved),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Meta acumulada global: ${currencyFormatter.format(totalTarget)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: globalRatio,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🌱 Aporte quincenal sugerido combinado: ~${currencyFormatter.format(finance.requiredCycleSavingsContribution)}',
                      style: const TextStyle(
                        color: AppColors.earthBrown,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tus Objetivos de Vida',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddGoalModal(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nueva Meta'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (finance.goals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.savings_outlined, color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin metas de ahorro activas',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Crea una meta (ej. Fondo de Emergencia, Vacaciones, Casa) para calcular tu ritmo de ahorro exacto.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddGoalModal(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Primera Meta'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: finance.goals.length,
                  itemBuilder: (context, index) {
                    final goal = finance.goals[index];
                    return SavingsGoalCard(
                      goal: goal,
                      onDeposit: () => _showDepositModal(context, goal),
                      onDelete: () => _confirmDeleteGoal(context, goal),
                    );
                  },
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal para Crear Nueva Meta
class _AddGoalModal extends StatefulWidget {
  const _AddGoalModal();

  @override
  State<_AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<_AddGoalModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController(text: '0');

  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  String _colorHex = '#2E5339';

  final List<String> _colors = ['#2E5339', '#6E4B33', '#8B5E3C', '#4A6B82', '#B47214', '#B33A2B'];

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forestGreen,
              surface: AppColors.surfaceCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);

    final goal = SavingsGoal(
      id: 'goal-${DateTime.now().millisecondsSinceEpoch}',
      userId: auth.currentUser?.id ?? 'user',
      title: _titleController.text.trim(),
      targetAmount: double.tryParse(_targetController.text) ?? 10000.0,
      currentAmount: double.tryParse(_currentController.text) ?? 0.0,
      targetDate: _targetDate,
      colorHex: _colorHex,
    );

    finance.addSavingsGoal(goal);
    budget.updateReport(finance);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nueva Meta de Ahorro',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(labelText: 'Nombre de la Meta (ej. Fondo de Emergencia)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Monto Objetivo (\$)'),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Válido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Ahorro Inicial (\$)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Selector de Fecha Objetivo
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fecha Límite', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.forestGreen, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            dateFormatter.format(_targetDate),
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Color
              const Text('Color de Identificación', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colors.map((hex) {
                  final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                  final isSelected = _colorHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _colorHex = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.textPrimary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Crear Meta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal para Abonar a una Meta
class _DepositModal extends StatefulWidget {
  final SavingsGoal goal;

  const _DepositModal({required this.goal});

  @override
  State<_DepositModal> createState() => _DepositModalState();
}

class _DepositModalState extends State<_DepositModal> {
  final _amountController = TextEditingController(text: '500');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _deposit() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);
    finance.depositToSavingsGoal(widget.goal.id, amount);
    budget.updateReport(finance);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Abonar a "${widget.goal.title}"',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ingresa el monto que transferirás a esta meta. Se descontará de tu dinero disponible.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              labelText: 'Monto a Abonar',
            ),
          ),
          const SizedBox(height: 16),

          // Botones de montos rápidos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [200, 500, 1000, 2500].map((quick) {
              return ActionChip(
                backgroundColor: AppColors.surfaceElevated,
                label: Text('+\$$quick', style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                onPressed: () {
                  final cur = double.tryParse(_amountController.text) ?? 0;
                  _amountController.text = (cur + quick).toStringAsFixed(0);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _deposit,
              child: const Text('Confirmar Abono'),
            ),
          ),
        ],
      ),
    );
  }
}
