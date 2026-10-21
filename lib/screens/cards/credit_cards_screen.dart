import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/constants/app_colors.dart';
import '../../models/credit_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/credit_card_widget.dart';

class CreditCardsScreen extends StatelessWidget {
  const CreditCardsScreen({super.key});

  void _showAddCardModal(BuildContext context, [CreditCard? cardToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditCardModal(cardToEdit: cardToEdit),
    );
  }

  void _confirmDeleteCard(BuildContext context, CreditCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Eliminar Tarjeta', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Estás seguro de que deseas eliminar la tarjeta ${card.bankName} ${card.cardName}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracottaRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<FinanceProvider>(context, listen: false).deleteCreditCard(card.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _hasCardsChanged(List<CreditCard> current, List<CreditCard> live) {
    if (current.length != live.length) return true;
    for (int i = 0; i < current.length; i++) {
      if (current[i].id != live[i].id ||
          current[i].currentBalance != live[i].currentBalance ||
          current[i].creditLimit != live[i].creditLimit ||
          current[i].cutOffDay != live[i].cutOffDay ||
          current[i].paymentDueDay != live[i].paymentDueDay ||
          current[i].bankName != live[i].bankName ||
          current[i].cardName != live[i].cardName ||
          current[i].colorHex != live[i].colorHex) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? auth.currentUser?.id;

    return StreamBuilder<List<CreditCard>>(
      stream: (currentUid != null && currentUid.isNotEmpty)
          ? finance.firestoreService.streamCreditCards(currentUid)
          : null,
      initialData: finance.cards,
      builder: (context, snapshot) {
        final List<CreditCard> cards;
        if (snapshot.connectionState == ConnectionState.active && snapshot.data != null) {
          cards = snapshot.data!;
        } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          cards = snapshot.data!;
        } else {
          cards = finance.cards;
        }

        if (snapshot.hasData && snapshot.data != null) {
          final liveList = snapshot.data!;
          if (_hasCardsChanged(finance.cards, liveList)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              finance.updateCardsFromStream(liveList);
            });
          }
        }

        CreditCard? bestCard;
        if (cards.isNotEmpty) {
          int maxGrace = -1;
          for (final c in cards) {
            final grace = c.getGracePeriodDaysIfUsedToday();
            if (grace > maxGrace) {
              maxGrace = grace;
              bestCard = c;
            }
          }
          bestCard ??= cards.first;
        }

        final totalCreditLimit = cards.fold(0.0, (sum, c) => sum + c.creditLimit);
        final totalCreditCardsBalance = cards.fold(0.0, (sum, c) => sum + c.currentBalance);
        final totalCreditAvailable = cards.fold(0.0, (sum, c) => sum + c.availableCredit);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Mis Tarjetas de Crédito'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_card, color: AppColors.forestGreen),
                tooltip: 'Nueva Tarjeta',
                onPressed: () => _showAddCardModal(context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner explicativo de optimización de cortes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreenMuted,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.forestGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_month, color: AppColors.forestGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Optimización de Fechas de Corte',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  bestCard != null
                                      ? 'Comprar hoy con ${bestCard.bankName} te da hasta ${bestCard.getGracePeriodDaysIfUsedToday()} días de crédito a 0% de interés.'
                                      : 'Registra tus tarjetas para identificar cuál tiene la ventana de gracia más larga hoy.',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Carrusel Visual de Tarjetas
                  if (cards.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.credit_card_off, color: AppColors.textMuted, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'No tienes tarjetas registradas',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Agrega tus plásticos para controlar sus días de corte y límites de forma automática.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddCardModal(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Primera Tarjeta'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final isBest = bestCard?.id == card.id;
                          return CreditCardWidget(
                            card: card,
                            isRecommendedToday: isBest,
                            onTap: () => _showAddCardModal(context, card),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Resumen Global de Tarjetas
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Línea de Crédito Global',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                Text(
                                  currencyFormatter.format(totalCreditLimit),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Saldo Total Ocupado',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                Text(
                                  currencyFormatter.format(totalCreditCardsBalance),
                                  style: const TextStyle(
                                    color: AppColors.terracottaRed,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Crédito Disponible Total',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                Text(
                                  currencyFormatter.format(totalCreditAvailable),
                                  style: const TextStyle(
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista Detallada con Acciones
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Administrar Plásticos',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        final isBest = bestCard?.id == card.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isBest ? AppColors.forestGreen.withOpacity(0.5) : AppColors.border,
                            ),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: card.color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          card.bankName,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          card.cardName,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Corte: Día ${card.cutOffDay} (${card.getDaysUntilCutOff()} días) • Pago: Día ${card.paymentDueDay}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                                onPressed: () => _showAddCardModal(context, card),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.terracottaRed, size: 18),
                                onPressed: () => _confirmDeleteCard(context, card),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modal para Registrar o Editar Tarjeta de Crédito
class _AddEditCardModal extends StatefulWidget {
  final CreditCard? cardToEdit;

  const _AddEditCardModal({this.cardToEdit});

  @override
  State<_AddEditCardModal> createState() => _AddEditCardModalState();
}

class _AddEditCardModalState extends State<_AddEditCardModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankController;
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late final TextEditingController _balanceController;

  int _cutOffDay = 15;
  int _paymentDueDay = 5;
  String _colorHex = '#2E5339';

  final List<String> _palette = [
    '#2E5339', // Verde Bosque
    '#6E4B33', // Café Tostado
    '#8B5E3C', // Café Arcilla
    '#4A6B82', // Azul Pizarra
    '#B47214', // Ámbar Cálido
    '#B33A2B', // Terracota
    '#2B2C28', // Carbón
  ];

  @override
  void initState() {
    super.initState();
    _bankController = TextEditingController(text: widget.cardToEdit?.bankName ?? '');
    _nameController = TextEditingController(text: widget.cardToEdit?.cardName ?? '');
    _limitController = TextEditingController(
      text: widget.cardToEdit != null ? widget.cardToEdit!.creditLimit.toStringAsFixed(0) : '25000',
    );
    _balanceController = TextEditingController(
      text: widget.cardToEdit != null ? widget.cardToEdit!.currentBalance.toStringAsFixed(0) : '0',
    );
    if (widget.cardToEdit != null) {
      _cutOffDay = widget.cardToEdit!.cutOffDay;
      _paymentDueDay = widget.cardToEdit!.paymentDueDay;
      _colorHex = widget.cardToEdit!.colorHex;
    }
  }

  @override
  void dispose() {
    _bankController.dispose();
    _nameController.dispose();
    _limitController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? auth.currentUser?.id ?? 'user';
    final cleanLimit = _limitController.text.replaceAll(',', '').replaceAll('\$', '').trim();
    final cleanBalance = _balanceController.text.replaceAll(',', '').replaceAll('\$', '').trim();

    final card = CreditCard(
      id: widget.cardToEdit?.id ?? 'card-${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUid,
      bankName: _bankController.text.trim(),
      cardName: _nameController.text.trim(),
      colorHex: _colorHex,
      cutOffDay: _cutOffDay,
      paymentDueDay: _paymentDueDay,
      creditLimit: double.tryParse(cleanLimit) ?? 20000.0,
      currentBalance: double.tryParse(cleanBalance) ?? 0.0,
    );

    if (widget.cardToEdit != null) {
      await finance.updateCreditCard(card);
    } else {
      await finance.addCreditCard(card);
    }

    if (mounted) {
      Navigator.pop(context);
    }
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
              Text(
                widget.cardToEdit != null ? 'Editar Tarjeta' : 'Registrar Tarjeta de Crédito',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bankController,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(labelText: 'Banco o Emisor (ej. BBVA, Nu, Banorte)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(labelText: 'Nombre o Nivel (ej. Oro, Platinum, Clásica)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _limitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Límite de Crédito (\$)'),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Válido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Saldo Actual Adeudado (\$)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Días de Corte y Pago
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _cutOffDay,
                      dropdownColor: AppColors.surfaceCard,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Día de Corte'),
                      items: List.generate(31, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('Día $d')))
                          .toList(),
                      onChanged: (v) => setState(() => _cutOffDay = v ?? 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _paymentDueDay,
                      dropdownColor: AppColors.surfaceCard,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Día Límite de Pago'),
                      items: List.generate(31, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('Día $d')))
                          .toList(),
                      onChanged: (v) => setState(() => _paymentDueDay = v ?? 5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Selector de Color
              const Text('Color del Plástico', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _palette.map((hex) {
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
                  child: Text(widget.cardToEdit != null ? 'Guardar Cambios' : 'Registrar Tarjeta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
