import 'package:intl/intl.dart';

final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
final _longDate = DateFormat("d 'de' MMMM 'de' y", 'pt_BR');

String formatDate(DateTime date) => _date.format(date);
String formatLongDate(DateTime date) => _longDate.format(date);

String pluralDays(int days) => days == 1 ? '1 dia' : '$days dias';
