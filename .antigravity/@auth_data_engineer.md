# 🔐 @auth_data_engineer.md - Agente de Backend, Autenticación y Persistencia

## 1. Identidad y Rol
- **Nombre del Agente**: `Backend, Auth & Data Persistence Engineer`
- **Responsabilidad Principal**:
  - Implementación de esquemas de datos, serialización JSON limpia, persistencia de sesión y preparación para sincronización con Supabase / REST / Firebase.
  - Asegurar la integridad de datos para que la aplicación funcione en modo local persistente con tokens de sesión y sea 100% interoperable al compilar en Flutter Web.

---

## 2. Entidades de Datos Principales
- **UserProfile**:
  - `id`: String (UUID)
  - `email`: String
  - `name`: String
  - `currency`: String ('MXN', 'USD', 'EUR')
  - `incomeType`: String ('quincenal' | 'mensual')
  - `incomeAmount`: double
  - `nextPayDate`: DateTime
  - `createdAt`: DateTime

- **Transaction / Expense**:
  - `id`: String (UUID)
  - `userId`: String
  - `title`: String
  - `amount`: double
  - `category`: String ('Alimentación', 'Transporte', 'Vivienda', 'Servicios', 'Entretenimiento', 'Salud', 'Educación', 'Otros')
  - `date`: DateTime
  - `periodicity`: String ('diario' | 'semanal' | 'mensual' | 'único')
  - `paymentMethod`: String ('efectivo' | 'debito' | 'tarjeta_credito')
  - `creditCardId`: String? (Opcional, enlazado si se paga con tarjeta)

- **CreditCard**:
  - `id`: String (UUID)
  - `userId`: String
  - `bankName`: String (e.g. 'BBVA', 'Nu', 'Santander', 'Amex')
  - `cardName`: String (e.g. 'Oro CashBack', 'Platino')
  - `colorHex`: String (e.g. '#8B5CF6', '#1E40AF', '#10B981')
  - `cutOffDay`: int (1 a 31)
  - `paymentDueDay`: int (1 a 31)
  - `creditLimit`: double
  - `currentBalance`: double

- **SavingsGoal**:
  - `id`: String (UUID)
  - `userId`: String
  - `title`: String
  - `targetAmount`: double
  - `currentAmount`: double
  - `targetDate`: DateTime
  - `colorHex`: String

---

## 3. Repositorios y Servicios
- `AuthService`: Gestión de sesión (login, register, logout, currentUser, sessionToken).
- `StorageService`: Persistencia local reactiva con `shared_preferences` y fallback a memoria/web storage.
- Sincronización transparente preparada para backend Supabase / Cloud Postgres.
