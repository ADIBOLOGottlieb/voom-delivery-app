import 'package:intl/intl.dart';

final _money = NumberFormat.decimalPattern('fr');
final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'fr');

String formatFcfa(int amount) => '${_money.format(amount)} FCFA';

String formatDateTime(DateTime date) => _dateTime.format(date);

/// « 14:30 » aujourd'hui, sinon « 12/10 14:30 ».
String formatTime(DateTime date) {
  final now = DateTime.now();
  final today = date.year == now.year && date.month == now.month && date.day == now.day;
  return DateFormat(today ? 'HH:mm' : 'dd/MM HH:mm', 'fr').format(date);
}

String formatKm(double km) => '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
