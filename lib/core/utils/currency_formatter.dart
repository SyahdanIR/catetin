/// Formatter utility for Indonesian Rupiah currency.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats an integer or double into standard Rupiah representation.
  /// Example: 13082900 -> "Rp 13.082.900"
  static String format(num amount, {bool includeSymbol = true, bool withSign = false}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs().round();
    final digits = absAmount.toString();

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    final formattedNumber = buffer.toString();

    if (withSign) {
      final sign = isNegative ? '-' : '+';
      return includeSymbol ? '$sign Rp $formattedNumber' : '$sign$formattedNumber';
    } else {
      final prefix = isNegative ? '-' : '';
      return includeSymbol
          ? '${prefix}Rp $formattedNumber'
          : '$prefix$formattedNumber';
    }
  }

  /// Compact representation for charts or small labels.
  /// Example: 1500000 -> "1.5jt", 45000 -> "45rb"
  static String formatCompact(num amount) {
    final absAmount = amount.abs();
    if (absAmount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (absAmount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toString();
  }
}
