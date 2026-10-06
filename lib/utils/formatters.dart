import 'package:intl/intl.dart';

final _money = NumberFormat.decimalPattern('fr');
final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'fr');

String formatFcfa(int amount) => '${_money.format(amount)} FCFA';

String formatDateTime(DateTime date) => _dateTime.format(date);

String formatKm(double km) => '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
