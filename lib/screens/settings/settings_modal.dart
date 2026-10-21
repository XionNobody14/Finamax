import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/spending_budget_provider.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final _incomeController = TextEditingController();
  String _incomeType = 'quincenal';
  String _currency = 'MXN';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user != null) {
      _incomeController.text = user.incomeAmount.toStringAsFixed(0);
      _incomeType = user.incomeType;
      _currency = user.currency;
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);

    // Actualizar perfil
    if (auth.currentUser != null) {
      final updated = auth.currentUser!.copyWith(
        incomeAmount: double.tryParse(_incomeController.text) ?? auth.currentUser!.incomeAmount,
        incomeType: _incomeType,
        currency: _currency,
      );
      await auth.updateProfile(updated);
      await finance.loadData(updated);
      budget.updateReport(finance);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada exitosamente'),
          backgroundColor: AppColors.forestGreen,
        ),
      );
    }
  }

  void _logout() {
    Navigator.pop(context);
    Provider.of<AuthProvider>(context, listen: false).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            const Text(
              'Ajustes de Presupuesto',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Configura los parámetros de tu nómina para el cálculo exacto de límites de gasto.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Parámetros de Nómina
            TextFormField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Monto de Ingreso Regular (\$)',
                prefixIcon: Icon(Icons.payments_outlined, color: AppColors.forestGreen),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _incomeType,
                    dropdownColor: AppColors.surfaceCard,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(labelText: 'Frecuencia de Cobro'),
                    items: const [
                      DropdownMenuItem(value: 'quincenal', child: Text('Quincenal')),
                      DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                    ],
                    onChanged: (v) => setState(() => _incomeType = v ?? 'quincenal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    dropdownColor: AppColors.surfaceCard,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(labelText: 'Moneda'),
                    items: const [
                      DropdownMenuItem(value: 'MXN', child: Text('MXN (\$ Peso)')),
                      DropdownMenuItem(value: 'USD', child: Text('USD (\$ Dólar)')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (€ Euro)')),
                    ],
                    onChanged: (v) => setState(() => _currency = v ?? 'MXN'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar Ajustes'),
              ),
            ),
            const SizedBox(height: 12),

            // Botón Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: AppColors.terracottaRed, size: 18),
                label: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.terracottaRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
