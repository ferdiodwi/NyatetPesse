import 'package:csv/csv.dart';

void main() {
  var x = const ListToCsvConverter();
  print(x.convert([['a', 'b'], ['c', 'd']]));
}
