/// Date formatting helper with Indonesian locale conventions.
class AppDateFormatter {
  AppDateFormatter._();

  static const List<String> days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Formats date into full group header: "Minggu, 25 Oktober 2026"
  static String formatGroupDate(DateTime date) {
    final dayName = days[date.weekday - 1];
    final day = date.day;
    final monthName = months[date.month - 1];
    final year = date.year;
    return '$dayName, $day $monthName $year';
  }

  /// Formats date into concise date: "25 Okt 2026"
  static String formatShortDate(DateTime date) {
    final day = date.day;
    final monthName = monthsShort[date.month - 1];
    final year = date.year;
    return '$day $monthName $year';
  }

  /// Formats period: "November 2026"
  static String formatMonthYear(DateTime date) {
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Returns calendar quarter (1..4) for a 1-based month.
  static int quarterForMonth(int month) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    return ((month - 1) ~/ 3) + 1;
  }

  /// Formats quarter span label: "Jan - Mar" for Q1.
  static String formatQuarterMonths(int quarter) {
    if (quarter < 1 || quarter > 4) {
      throw RangeError.range(quarter, 1, 4, 'quarter');
    }
    final startMonth = (quarter - 1) * 3;
    final endMonth = startMonth + 2;
    return '${monthsShort[startMonth]} - ${monthsShort[endMonth]}';
  }

  /// Formats quarter and year: "Q1 2026 (Jan - Mar)"
  static String formatQuarterYear(int year, int quarter, {bool includeMonths = true}) {
    if (!includeMonths) {
      return 'Q$quarter $year';
    }
    return 'Q$quarter $year (${formatQuarterMonths(quarter)})';
  }

  /// Formats an inclusive calendar date range compactly in Indonesian.
  static String formatDateRange(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return formatShortDate(start);
    }
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day} ${monthsShort[end.month - 1]} ${end.year}';
    }
    if (start.year == end.year) {
      return '${start.day} ${monthsShort[start.month - 1]} - ${end.day} ${monthsShort[end.month - 1]} ${end.year}';
    }
    return '${formatShortDate(start)} - ${formatShortDate(end)}';
  }

  /// Checks if two dates are on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Adds [monthDelta] calendar months while clamping day to target month length.
  static DateTime addMonthsClamped(DateTime date, int monthDelta) {
    final totalMonths = date.year * 12 + (date.month - 1) + monthDelta;
    final targetYear =
        totalMonths >= 0 ? totalMonths ~/ 12 : ((totalMonths - 11) ~/ 12);
    final targetMonth = (totalMonths % 12) + 1;
    final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final safeDay =
        date.day <= daysInTargetMonth ? date.day : daysInTargetMonth;
    return DateTime(
      targetYear,
      targetMonth,
      safeDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Subtracts one calendar year while clamping Feb 29 to Feb 28 in non-leap years.
  static DateTime subtractOneYear(DateTime date) {
    final targetYear = date.year - 1;
    final daysInTargetMonth = DateTime(targetYear, date.month + 1, 0).day;
    final safeDay =
        date.day <= daysInTargetMonth ? date.day : daysInTargetMonth;
    return DateTime(
      targetYear,
      date.month,
      safeDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
