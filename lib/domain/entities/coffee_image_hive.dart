import 'package:hive/hive.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';

class CoffeeImageAdapter extends TypeAdapter<CoffeeImage> {
  @override
  final int typeId = 1;

  @override
  CoffeeImage read(BinaryReader r) {
    final id = r.readString();
    final url = r.readString();
    return CoffeeImage(id: id, remoteUrl: Uri.parse(url));
  }

  @override
  void write(BinaryWriter w, CoffeeImage obj) {
    w
      ..writeString(obj.id)
      ..writeString(obj.remoteUrl.toString());
  }
}
