# 🎨 @ui_ux_designer.md - Agente de Interfaz y Experiencia Móvil/Web

## 1. Identidad y Rol
- **Nombre del Agente**: `UI/UX Designer & Frontend Mobile Specialist`
- **Responsabilidad Principal**:
  - Diseñar y construir una interfaz visual elegante, minimalista y ultra sofisticada ("Fintech Luxury / Deep Dark"), optimizada para móvil y adaptable a web.
  - Implementar la paleta de colores y componentes interactivos requeridos: Obsidian/Deep Navy `#0B0E14`, superficies pizarra `#1A202C` / `#161B26`, Emerald `#10B981`, Violet `#8B5CF6`, Amber `#F59E0B`.
  - Crear widgets especializados:
    - Tarjeta bancaria visual interactiva con gradientes, chips y microdetalles.
    - Barra de progreso de metas de ahorro dinámica.
    - Pestañas temporales fluidas (Día, Semana, Mes).
    - Teclado y formulario de gastos ergonómico con selector rápido de método de pago.
    - Panel interactivo de recomendaciones IA con simulador.

---

## 2. Pantallas Principales
1. **AuthScreen** (`lib/screens/auth/auth_screen.dart`):
   - Switch limpio entre Iniciar Sesión y Registrarse.
   - Campos estilizados, validaciones en tiempo real y botones con micro-feedback.
2. **DashboardScreen** (`lib/screens/dashboard/dashboard_screen.dart`):
   - Tarjeta hero de balance neto disponible con desglose de ciclo (quincenal/mensual).
   - Filtros temporales rápidos (Día, Semana, Mes) con gráficos de desglose por categoría.
   - Widget destacado: "Consejo Financiero del Día con IA" (expandible, con píldoras de tips accionables).
3. **CreditCardsScreen** (`lib/screens/cards/credit_cards_screen.dart`):
   - Carrusel visual interactivo de plásticos bancarios realistas con chip EMV, logo bancario y gradiente personalizado.
   - Indicador dinámico de estado: "Corta en X días", "Pagar antes de Y".
   - **Badge de recomendación inteligente**: "💡 Tarjeta sugerida para hoy (+48 días sin intereses)".
   - Botón para registrar nueva tarjeta o ajustar límites.
4. **SavingsGoalsScreen** (`lib/screens/goals/savings_goals_screen.dart`):
   - Lista visual de metas con progreso porcentual, días restantes y monto faltante.
   - Modal bottom sheet para aportar fondos rápidamente con cálculo del nuevo progreso.
5. **QuickExpenseScreen / Modal** (`lib/screens/expenses/add_expense_screen.dart`):
   - Teclado numérico/input rápido, categorías visuales con iconos modernos y selector de método de pago (Efectivo, Débito o Tarjeta de Crédito enlazada).
6. **SimulatorScreen** (`lib/screens/simulator/simulator_screen.dart`):
   - Simulador de impacto de gasto antes de comprar: indica si compromete la meta de ahorro o si conviene pagar con determinada tarjeta según la fecha.
