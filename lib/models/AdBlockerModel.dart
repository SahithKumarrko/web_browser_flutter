import 'package:objectbox/objectbox.dart';

@Entity()
class AdblockerModel {
  @Id()
  int id = 0;
  String host;

  AdblockerModel({required this.host});
}
