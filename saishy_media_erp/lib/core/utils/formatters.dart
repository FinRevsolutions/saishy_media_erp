import 'package:intl/intl.dart';

class AppFormatters {
  static final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final _compactFmt  = NumberFormat.compact(locale: 'en_IN');

  static String currency(double amount) => _currencyFmt.format(amount);
  static String compact(double amount)  => '₹${_compactFmt.format(amount)}';

  static String date(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String dateShort(DateTime d) => DateFormat('dd MMM yy').format(d);
  static String dateTime(DateTime d) => DateFormat('dd MMM yyyy, hh:mm a').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
}
