import 'package:intl/intl.dart';

class SessionFormatters {
  SessionFormatters._();

  static final NumberFormat priceCurrency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'DT',
    decimalDigits: 3,
  );

  static String formatPrice(double price) => priceCurrency.format(price);

  static String formatDuration(double hours) {
    if (hours == 1) return '1 heure';
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()} heures';
    }
    return '${hours.toStringAsFixed(1).replaceAll('.', ',')} heures';
  }

  static String formatDurationShort(double hours) {
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()} h';
    }
    return '${hours.toStringAsFixed(1).replaceAll('.', ',')} h';
  }

  static String formatDurationForInput(double hours) {
    if (hours == hours.roundToDouble()) {
      return hours.toInt().toString();
    }
    return hours.toString();
  }
}
