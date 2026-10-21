# 📋 Pizarra de Orquestación y Refactorización: FinamaX

> **Patrón**: Coordinator-Workers  
> **Estado**: INTEGRACIÓN FIREBASE & CLOUD FIRESTORE COMPLETADA (PROYECTO "FNX") 🔥  
> **Enfoque**: Retirada total de Gemini / LLMs externos, motor matemático local de presupuesto, paleta de colores natural (Hueso, Verde Botánico, Café Tostado), generación de iconos oficiales, infraestructura Firebase (Auth + Cloud Firestore con aislamiento y persistencia offline) y compilación de release APK.

---

## 🎯 Registro de Hitos

### 1. Eliminación de LLMs & Motor Matemático Local
- [x] Retirada de dependencias `google_generative_ai`, llamadas REST y llaves de API en `pubspec.yaml` y código fuente.
- [x] Eliminación de archivos heredados de IA (`ai_advice.dart`, `financial_advisor_service.dart`, `ai_advisor_provider.dart`).
- [x] Creación del servicio determinista [`lib/services/spending_budget_calculator.dart`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/services/spending_budget_calculator.dart):
  - [x] Cálculo exacto de ahorro diario requerido: $\frac{\text{Monto Objetivo} - \text{Monto Actual}}{\text{Días Faltantes}}$.
  - [x] Saldo real disponible del ciclo actual (restando compromisos fijos y pagos inmediatos).
  - [x] Presupuesto diario sugerido (Límite Máximo de Gasto Permitido): $\frac{\text{Ingreso Disponible} - \text{Ahorro Total Comprometido}}{\text{Días Restantes del Ciclo}}$.
  - [x] Estado de salud presupuestal: **En meta** (Verde Bosque), **Ajustado** (Ámbar), **Excedido** (Terracota).
  - [x] Indicador de impacto: *"Si gastas menos de $X al día, alcanzarás tu meta de [Meta] para el [Fecha]"*.
  - [x] Reglas inteligentes de tarjetas de crédito sin IA (detección de la tarjeta con mayor ventana de gracia a tasa 0%).
  - [x] Simulador matemático de compras antes de pagar.
- [x] Creación de [`SpendingBudgetProvider`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/providers/spending_budget_provider.dart) conectado al árbol de widgets.

### 2. Identidad Visual: "Earthy Organic / Botanical Warmth"
- [x] Paleta de colores en [`lib/core/constants/app_colors.dart`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/core/constants/app_colors.dart):
  - Fondo general (Scaffold): Color hueso / lino natural claro (`#F9F7F2` / `#F5F3EC`).
  - Superficies y tarjetas: Blanco marfil cálido (`#FFFFFF` / `#FCFBF9`) con bordes suaves (`#E6E1D8`).
  - Acento Verde Botánico: Verde bosque suave (`#2E5339`) para botones principales, indicadores de ingreso y progreso de metas.
  - Acento Café Tostado: Café terroso (`#6E4B33`) para encabezados secundarios y detalles.
  - Neutros de texto: Carbón orgánico profundo (`#2B2C28`) para títulos legibles y café apagado (`#766E65`) para subtítulos y fechas.
  - Tarjetas con esquinas redondeadas (18px) y sombras de bajísimo contraste.
- [x] Reestilizado completo de todas las pantallas y widgets:
  - [`AuthScreen`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/screens/auth/auth_screen.dart)
  - [`DashboardScreen`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/screens/dashboard/dashboard_screen.dart)
  - [`CreditCardsScreen`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/screens/cards/credit_cards_screen.dart)
  - [`SavingsGoalsScreen`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/screens/goals/savings_goals_screen.dart)
  - [`AddExpenseScreen`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/screens/expenses/add_expense_screen.dart)
  - [`SimulatorScreen`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/screens/simulator/simulator_screen.dart)
  - [`SettingsModal`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/screens/settings/settings_modal.dart)

### 3. Icono Oficial de la Aplicación
- [x] Generación del isotipo vectorial minimalista en `assets/icon/app_icon.png` (1024x1024):
  - Fondo color hueso cálido (`#F9F7F2`).
  - Brote / hoja botánica estilizada fusionada orgánicamente con una moneda/tarjeta en tonos verde bosque (`#2E5339`) y café terroso (`#6E4B33`).
- [x] Configuración de `flutter_launcher_icons` en `pubspec.yaml`.
- [x] Ejecución de `dart run flutter_launcher_icons` estampando los iconos adaptativos en Android e iOS.

### 4. Integración de Infraestructura y Base de Datos (Firebase / Cloud Firestore - Proyecto "FNMAX")
- [x] Herramientas oficiales preparadas: `firebase-tools` (v15.34.0), `flutterfire_cli` (v1.0.0).
- [x] Autenticación formal con Firebase CLI completada (`andreschavezv2003@gmail.com`).
- [x] Vinculación oficial con el proyecto existente en Firebase: **FNMAX** (`fnmax-e6a2b`, Project Number: `486506269027`).
- [x] Registro y descarga oficial de credenciales multiplataforma:
  - Android App ID: `1:486506269027:android:fee2cb7a4190a001bd6b56`
  - iOS App ID: `1:486506269027:ios:f1880eb9b7bc12c9bd6b56`
  - Web App ID: `1:486506269027:web:3e422651b1dbb3d5bd6b56`
- [x] Generación de archivos oficiales con API Keys reales:
  - [`android/app/google-services.json`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/android/app/google-services.json)
  - [`ios/Runner/GoogleService-Info.plist`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/ios/Runner/GoogleService-Info.plist)
  - [`lib/firebase_options.dart`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/firebase_options.dart)
- [x] Configuración nativa Android:
  - `android/build.gradle`: Classpath `com.google.gms:google-services:4.4.1`.
  - `android/app/build.gradle`: Plugin `com.google.gms.google-services`, `compileSdkVersion 34`, `targetSdkVersion 34`, `minSdkVersion 21`, `multiDexEnabled true`.
  - `lib/main.dart`: Inicialización asíncrona oficial `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
- [x] Autenticación de Usuarios (`lib/services/auth_service.dart`):
  - Implementación formal con `FirebaseAuth.instance`:
    - Registro (`createUserWithEmailAndPassword`).
    - Inicio de sesión (`signInWithEmailAndPassword`).
    - Cierre de sesión (`signOut`).
    - Flujo reactivo con `authStateChanges`.
    - Modo Demo con cuenta persistida o fallback offline.
  - Sin roles administrativos; simétrico y transparente para cualquier usuario.
- [x] Modelo de Datos y Sincronización en Cloud Firestore (`lib/services/firestore_service.dart`):
  - Persistencia offline nativa habilitada (`Settings(persistenceEnabled: true, cacheSizeBytes: unlimited)`).
  - Colección raíz: `users/{userId}` (email, name, incomeType, incomeAmount, currency, nextPayDate, createdAt, updatedAt).
  - Subcolecciones recursivas bajo `users/{userId}/`:
    - `expenses`: `{ id, userId, title, amount, category, date, periodicity, paymentMethod, creditCardId }`.
    - `credit_cards`: `{ id, userId, bankName, cardName, colorHex, cutOffDay, paymentDueDay, creditLimit, currentBalance }`.
    - `savings_goals`: `{ id, userId, title, targetAmount, currentAmount, targetDate, colorHex }`.
  - Métodos CRUD completos y reactivos (Streams y Futures).
  - Respaldo híbrido y sincronización automática bidireccional en [`FinanceProvider`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/lib/providers/finance_provider.dart).
- [x] Reglas Oficiales de Seguridad en [`firestore.rules`](file:///c:/Users/andyc/OneDrive/Desktop/Projects/FinamaX/firestore.rules):
  - Diseñadas y validadas por el subagente especialista `firestore-rules-author`.
  - `rules_version = '2';`
  - Aislamiento estricto por usuario:
    ```javascript
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    ```
  - Denegación explícita por defecto para cualquier otra colección:
    ```javascript
    match /{document=**} {
      allow read, write: if false;
    }
    ```

### 5. QA, Compilación y Entrega
- [x] `flutter analyze`: **0 advertencias, 0 errores (Clean)**.
- [x] `flutter test`: **7/7 pruebas unitarias y de widgets aprobadas**.
- [x] Compilación en modo release (`flutter build apk --release`).
- [x] Binario final ubicado en la raíz del proyecto: `./FinamaX.apk`.
