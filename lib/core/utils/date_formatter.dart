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

  /// Checks if two dates are on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
