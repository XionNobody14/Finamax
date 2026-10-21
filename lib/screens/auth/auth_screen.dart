import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/spending_budget_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController(text: '18500');

  String _incomeType = 'quincenal';
  String _currency = 'MXN';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);

    bool success = false;
    if (_isLogin) {
      success = await auth.login(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      final income = double.tryParse(_incomeController.text) ?? 15000.0;
      success = await auth.register(
        email: _emailController.text,
        name: _nameController.text,
        password: _passwordController.text,
        incomeAmount: income,
        incomeType: _incomeType,
        currency: _currency,
      );
    }

    if (success && mounted && auth.currentUser != null) {
      await finance.loadData(auth.currentUser!);
      budget.updateReport(finance);
    }
  }

  Future<void> _submitDemo() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final budget = Provider.of<SpendingBudgetProvider>(context, listen: false);

    final success = await auth.loginAsDemo();
    if (success && mounted && auth.currentUser != null) {
      await finance.loadData(auth.currentUser!);
      budget.updateReport(finance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Isotipo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 64,
                            height: 64,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.eco,
                              color: AppColors.forestGreen,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FinamaX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestión Financiera Natural & Optimización de Ahorro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Selector Login / Registro
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLogin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLogin ? AppColors.surfaceCard : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _isLogin ? Border.all(color: AppColors.border) : null,
                                boxShadow: _isLogin ? AppColors.softShadow : null,
                              ),
                              child: Text(
                                'Iniciar Sesión',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isLogin ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: _isLogin ? FontWeight.w800 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLogin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLogin ? AppColors.surfaceCard : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: !_isLogin ? Border.all(color: AppColors.border) : null,
                                boxShadow: !_isLogin ? AppColors.softShadow : null,
                              ),
                              child: Text(
                                'Registrarme',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isLogin ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: !_isLogin ? FontWeight.w800 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos de Formulario
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.forestGreen),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.mail_outline, color: AppColors.forestGreen),
                    ),
                    validator: (v) => v == null || !v.contains('@') ? 'Ingresa un correo válido' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forestGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),

                  if (!_isLogin) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _incomeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Monto de Ingreso Regular',
                        prefixIcon: const Icon(Icons.attach_money, color: AppColors.forestGreen),
                        suffixText: _currency,
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Ingresa un monto válido' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _incomeType,
                            dropdownColor: AppColors.surfaceCard,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              labelText: 'Ciclo de Pago',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Moneda',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
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
                  ],

                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.terracottaMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.terracottaRed.withOpacity(0.4)),
                      ),
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: AppColors.terracottaRed, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botón Principal
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isLogin ? 'Acceder a mi Cuenta' : 'Crear mi Cuenta'),
                  ),

                  const SizedBox(height: 16),

                  // Botón Demo Instantáneo
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _submitDemo,
                    icon: const Icon(Icons.eco, color: AppColors.forestGreen, size: 18),
                    label: const Text(
                      'Explorar en Modo Demo (1 Clic)',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: AppColors.surfaceCard,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
