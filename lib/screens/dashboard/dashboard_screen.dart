import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/spending_budget_provider.dart';
import '../../models/credit_card.dart';
import '../../services/spending_budget_calculator.dart';
import '../../widgets/ai_tip_pill.dart';
import '../../widgets/transaction_tile.dart';
import '../settings/settings_modal.dart';
import '../expenses/add_expense_screen.dart';

enum TimeFilter { dia, semana, mes }

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TimeFilter _selectedFilter = TimeFilter.mes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final finance = Provider.of<FinanceProvider>(context, listen: false);
      final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);
      if (finance.profile != null) {
        budget.updateReport(finance);
      }
    });
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsModal(),
    );
  }

  void _openAddExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  Color _getHealthColor(BudgetHealth status) {
    switch (status) {
      case BudgetHealth.healthy:
        return AppColors.forestGreen;
      case BudgetHealth.tight:
        return AppColors.warmAmber;
      case BudgetHealth.exceeded:
        return AppColors.terracottaRed;
    }
  }

  Color _getHealthBgColor(BudgetHealth status) {
    switch (status) {
      case BudgetHealth.healthy:
        return AppColors.forestGreenMuted;
      case BudgetHealth.tight:
        return AppColors.warmAmberMuted;
      case BudgetHealth.exceeded:
        return AppColors.terracottaMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final budgetProvider = Provider.of<SpendingBudgetProvider>(context);

    // Asegurar que el reporte esté calculado
    final report = budgetProvider.currentReport ??
        (finance.profile != null
            ? SpendingBudgetCalculator.calculateReport(
                profile: finance.profile!,
                cards: finance.cards,
                transactions: finance.transactions,
                goals: finance.goals,
                currentCycleExpenses: finance.currentCycleExpenses,
                daysUntilNextPay: finance.daysUntilNextPay,
              )
            : null);

    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final user = auth.currentUser;

    if (finance.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.forestGreen),
        ),
      );
    }

    final filteredTransactions = switch (_selectedFilter) {
      TimeFilter.dia => finance.transactionsToday,
      TimeFilter.semana => finance.transactionsThisWeek,
      TimeFilter.mes => finance.transactionsThisMonth,
    };

    final filteredTotal = switch (_selectedFilter) {
      TimeFilter.dia => finance.totalExpensesToday,
      TimeFilter.semana => finance.totalExpensesThisWeek,
      TimeFilter.mes => finance.totalExpensesThisMonth,
    };

    final healthColor = report != null ? _getHealthColor(report.healthStatus) : AppColors.forestGreen;
    final healthBg = report != null ? _getHealthBgColor(report.healthStatus) : AppColors.forestGreenMuted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            if (user != null) {
              await finance.loadData(user);
              budgetProvider.updateReport(finance);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra Superior: Saludo y Configuración
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user?.name ?? 'Usuario'} 🌱',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.forestGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cobro en ${finance.daysUntilNextPay} días (${user?.incomeType ?? 'quincenal'})',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: const Icon(Icons.tune, color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // TARJETA HERO: LÍMITE DE GASTO Y SALUD PRESUPUESTAL
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
                            'LÍMITE MÁXIMO DE GASTO HOY',
                            style: TextStyle(
                              color: AppColors.earthBrown,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: healthBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: healthColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: healthColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  report?.healthLabel ?? 'En meta',
                                  style: TextStyle(
                                    color: healthColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currencyFormatter.format(report?.dailyBudgetSuggested ?? finance.suggestedDailyBudget),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Límite semanal sugerido: ~${currencyFormatter.format(report?.weeklyBudgetSuggested ?? (finance.suggestedDailyBudget * 7))}',
                        style: const TextStyle(
                          color: AppColors.earthBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Indicador de Impacto hacia las Metas de Ahorro
                      if (report != null && report.impactIndicator.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.savings_outlined, color: AppColors.forestGreen, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  report.impactIndicator,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14),

                      // Desglose del ciclo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCycleBreakdownItem(
                            label: 'Ingreso Ciclo',
                            amount: currencyFormatter.format(finance.cycleIncome),
                            color: AppColors.forestGreen,
                          ),
                          _buildCycleBreakdownItem(
                            label: 'Gastos Ciclo',
                            amount: currencyFormatter.format(finance.currentCycleExpenses),
                            color: AppColors.terracottaRed,
                          ),
                          _buildCycleBreakdownItem(
                            label: 'Ahorro Comprometido',
                            amount: currencyFormatter.format(report?.totalCommittedSavingsInCycle ?? finance.requiredCycleSavingsContribution),
                            color: AppColors.earthBrown,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // TARJETA DE RECOMENDACIÓN INTELIGENTE DE CRÉDITO SIN IA
                if (report != null)
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.earthBrownMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.credit_card, color: AppColors.earthBrown, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Estrategia de Pagos & Fechas de Corte',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          report.creditCardAdvice,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Píldoras de recomendación
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: report.actionableTips.map((tip) {
                            return AITipPill(
                              text: tip,
                              color: AppColors.forestGreen,
                              onTap: () {
                                if (tip.contains('TDC')) {
                                  widget.onNavigateTab?.call(1);
                                } else if (tip.contains('ahorro')) {
                                  widget.onNavigateTab?.call(2);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 22),

                // SELECTOR DE DESGLOSE TEMPORAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Historial de Gastos',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _buildFilterTab(TimeFilter.dia, 'Día'),
                          _buildFilterTab(TimeFilter.semana, 'Semana'),
                          _buildFilterTab(TimeFilter.mes, 'Mes'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Resumen del periodo activo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total ${_selectedFilter == TimeFilter.dia ? 'de hoy' : (_selectedFilter == TimeFilter.semana ? 'de la semana' : 'del mes')}:',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(filteredTotal),
                        style: const TextStyle(
                          color: AppColors.terracottaRed,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Lista de Transacciones Filtradas
                if (filteredTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.receipt_outlined, color: AppColors.textMuted.withOpacity(0.5), size: 42),
                        const SizedBox(height: 8),
                        const Text(
                          'No hay gastos registrados en este periodo',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      String? cardName;
                      if (tx.creditCardId != null) {
                        final card = finance.cards.firstWhere(
                          (c) => c.id == tx.creditCardId,
                          orElse: () => CreditCard(
                            id: '',
                            userId: '',
                            bankName: 'TDC',
                            cardName: '',
                            cutOffDay: 1,
                            paymentDueDay: 20,
                            creditLimit: 0,
                          ),
                        );
                        cardName = card.bankName;
                      }
                      return TransactionTile(
                        transaction: tx,
                        cardName: cardName,
                        onDelete: () => finance.deleteExpense(tx.id),
                      );
                    },
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Registrar Gasto',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildCycleBreakdownItem({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(TimeFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
