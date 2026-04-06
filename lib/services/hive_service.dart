import 'package:hive/hive.dart';

class HiveService {
  final box = Hive.box('transactions');

  List getAll() => box.values.toList();

  void add(Map data) => box.add(data);

  void delete(int index) => box.deleteAt(index);
}