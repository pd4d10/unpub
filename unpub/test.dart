import 'package:intl/intl.dart';

main(List<String> args) {
  var x = DateFormat('yyyyMMdd').format(DateTime.now());
  print(x);
}
