/// Helper para cálculos de fechas financieras precisas, considerando
/// años bisiestos, meses de 28, 29, 30 y 31 días y desbordamientos de mes.
class DateCalcHelper {
  /// Retorna si un año es bisiesto.
  static bool isLeapYear(int year) {
    if (year % 4 != 0) return false;
    if (year % 100 != 0) return true;
    return year % 400 == 0;
  }

  /// Retorna el número de días en un mes y año específico.
  static int daysInMonth(int year, int month) {
    if (month == 2) {
      return isLeapYear(year) ? 29 : 28;
    }
    const daysPerMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysPerMonth[month];
  }

  /// Construye una fecha segura ajustando el día si excede el fin de mes.
  static DateTime safeDate(int year, int month, int day, [int hour = 0, int minute = 0]) {
    final maxDays = daysInMonth(year, month);
    final clampedDay = day.clamp(1, maxDays);
    return DateTime(year, month, clampedDay, hour, minute);
  }

  /// Calcula la próxima fecha en que ocurrirá un día del mes determinado
  /// a partir de una fecha de referencia.
  static DateTime getNextOccurrenceOfDay(int targetDay, DateTime referenceDate) {
    final ref = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final currentMonthDate = safeDate(ref.year, ref.month, targetDay);

    if (currentMonthDate.isAfter(ref) || currentMonthDate.isAtSameMomentAs(ref)) {
      return currentMonthDate;
    }

    // Pasa al siguiente mes
    final nextMonth = ref.month == 12 ? 1 : ref.month + 1;
    final nextYear = ref.month == 12 ? ref.year + 1 : ref.year;
    return safeDate(nextYear, nextMonth, targetDay);
  }

  /// Calcula la fecha de corte más reciente (último corte ocurrido).
  static DateTime getPreviousOccurrenceOfDay(int targetDay, DateTime referenceDate) {
    final ref = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final currentMonthDate = safeDate(ref.year, ref.month, targetDay);

    if (currentMonthDate.isBefore(ref) || currentMonthDate.isAtSameMomentAs(ref)) {
      return currentMonthDate;
    }

    // Pasa al mes anterior
    final prevMonth = ref.month == 1 ? 12 : ref.month - 1;
    final prevYear = ref.month == 1 ? ref.year - 1 : ref.year;
    return safeDate(prevYear, prevMonth, targetDay);
  }

  /// Calcula los días restantes hasta la fecha objetivo
  static int daysUntil(DateTime target, DateTime reference) {
    final t = DateTime(target.year, target.month, target.day);
    final r = DateTime(reference.year, reference.month, reference.day);
    return t.difference(r).inDays;
  }
}
