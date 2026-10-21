# 🌿 FinamaX - Finanzas Personales & Optimización de Ahorro

**FinamaX** es una aplicación móvil moderna desarrollada en **Flutter** bajo una estética botánica y orgánica cálida (*Earthy Organic / Botanical Warmth*). Implementa un **motor matemático determinista y 100% local** para el cálculo exacto de presupuestos diarios permitidos hacia metas de ahorro y la optimización inteligente de fechas de corte de tarjetas de crédito (ganando entre 45 y 50 días de financiamiento libre de intereses).

---

## 🍃 Novedades de la Versión Refactorizada

1. **Motor Matemático 100% Local (Cero LLMs / Sin Dependencias Externas)**:
   - Eliminación completa de dependencias de IA, variables de API Key y llamadas de red.
   - Cálculo del ahorro diario/quincenal requerido:
     $$\text{Ahorro Requerido por Día} = \frac{\text{Monto Objetivo} - \text{Monto Actual}}{\text{Días Faltantes hasta la Fecha Límite}}$$
   - Saldo real disponible del ciclo actual (restando compromisos fijos y deudas inmediatas).
   - Presupuesto diario sugerido (Límite Máximo de Gasto Permitido):
     $$\text{Presupuesto Diario Sugerido} = \frac{\text{Ingreso Disponible del Ciclo} - \text{Ahorro Total Comprometido}}{\text{Días Restantes del Ciclo}}$$
   - Clasificación de salud presupuestal: **En meta** (Verde Bosque), **Ajustado** (Ámbar Cálido) o **Excedido** (Terracota).
   - Indicador de impacto claro: *"Si gastas menos de $X al día, alcanzarás tu meta de [Meta] para el [Fecha]"*.
   - Reglas deterministas de corte: Detecta cuál plástico bancario conviene usar hoy según su fecha de corte.

2. **Identidad Visual "Earthy Organic / Botanical Warmth"**:
   - **Fondo general (Scaffold)**: Color hueso / lino natural claro (`#F9F7F2`).
   - **Superficies y tarjetas**: Blanco marfil cálido (`#FFFFFF` / `#FCFBF9`) con bordes suaves (`#E6E1D8`) y esquinas redondeadas de 18px.
   - **Acento Verde Botánico**: Verde bosque suave (`#2E5339`) para botones principales, indicadores de ingreso y progreso de metas.
   - **Acento Café Tostado**: Café cálido (`#6E4B33`) para encabezados secundarios y detalles.
   - **Tipografía y Neutros**: Carbón orgánico profundo (`#2B2C28`) para máxima legibilidad y café apagado (`#766E65`) para subtítulos.

3. **Icono Oficial Integrado**:
   - Isotipo minimalista con fondo color hueso cálido y un brote natural fusionado suavemente con una moneda/tarjeta estilizada en tonos verde bosque y café terroso (`assets/icon/app_icon.png` 1024x1024).
   - Estampado con `flutter_launcher_icons` en todas las densidades de Android e iOS.

4. **Binario APK Listo en la Raíz**:
   - Compilado en modo release y ubicado en la raíz del proyecto:
     `./FinamaX.apk` (20.4 MB).

---

## 📱 Instalación del APK en tu Dispositivo

El instalador Android APK ya está generado y listo para transferir:

* **Ruta local**:
  ```
  c:\Users\andyc\OneDrive\Desktop\Projects\FinamaX\FinamaX.apk
  ```
* Puedes transferir este archivo directamente a tu teléfono mediante cable USB, Google Drive, WhatsApp o Telegram, o instalarlo por ADB:
  ```bash
  adb install FinamaX.apk
  ```

---

## 🛠️ Ejecución y Pruebas en Desarrollo

```bash
# Análisis estático (0 advertencias, 0 errores)
flutter analyze

# Suite de pruebas unitarias y de widgets (7/7 aprobadas)
flutter test

# Ejecución en dispositivo, emulador o navegador web
flutter run
```
