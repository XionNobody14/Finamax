# 🧠 @finance_logic_ai.md - Agente de Métricas Financieras y Google Gemini API

## 1. Identidad y Rol
- **Nombre del Agente**: `Financial Metrics & Google Gemini AI Engine`
- **Responsabilidad Principal**:
  - Implementar el motor de cálculo financiero (ingresos prorrateados, flujo de caja en tiempo real, net available balance, metas de ahorro periódicas).
  - Algoritmo de optimización de tarjetas de crédito (detección de fecha de corte para ganar 45-50 días de financiamiento libre de intereses).
  - Integración robusta con el SDK de Google Gemini (`google_generative_ai`), construyendo un contexto analítico exhaustivo y recibiendo recomendaciones estructuradas y accionables.

---

## 2. Fórmulas y Reglas de Negocio
1. **Balance Disponible Neto**:
   $$\text{Disponible} = \text{Ingresos del Ciclo} - \text{Gastos Realizados} - \text{Saldos Exigibles Tarjetas} - \text{Aportación Ahorro Requerida}$$
2. **Ingreso Prorrateado**:
   - Quincenal: Se calcula con base en la quincena actual o mensual dividida entre 2.
3. **Optimización de Tarjetas de Crédito**:
   - Para cada tarjeta $C_i$, calcular:
     - Próxima fecha de corte ajustada a días de mes válidos (28/29 en feb, 30 en meses de 30 días, 31 en el resto).
     - Días transcurridos desde el último corte y días restantes para el próximo corte.
     - **Tarjeta recomendada para hoy**: Aquella cuyo corte haya ocurrido más recientemente (1-3 días después de corte), otorgando la máxima ventana de gracia (45-50 días hasta el pago).
4. **Metas de Ahorro**:
   - Días restantes = $\max(1, \text{targetDate} - \text{hoy})$.
   - Aportación diaria/semanal/quincenal requerida para alcanzar el faltante.

---

## 3. Integración Google Gemini API
- **SDK**: `google_generative_ai` con modelo `gemini-1.5-flash` (o `gemini-pro`).
- **Prompt Estratégico de Sistema**:
  > "Eres un asesor financiero estratégico y empático. Analiza el flujo de caja del usuario y sus tarjetas de crédito. Tu objetivo es indicarle exactamente cómo jugar con sus fechas de corte (por ejemplo, usar la tarjeta cuyo corte acaba de pasar para ganar hasta 45 o 50 días de financiamiento sin intereses), definir un límite máximo de gasto diario/semanal sugerido y diseñar una estrategia de pagos para que su meta de ahorro mensual se cumpla sin caer en sobreendeudamiento."
- **Entrega de Respuestas**:
  - Tips accionables en formato estructurado (píldoras de recomendación rápida).
  - Simulación de gastos y análisis de impacto en tiempo real.
