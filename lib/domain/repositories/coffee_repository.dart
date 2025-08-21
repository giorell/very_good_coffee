import 'package:very_good_coffee/domain/entities/coffee_image.dart';

abstract class CoffeeRepository {
  Future<CoffeeImage> fetchRandom();
  Future<void> saveFavorite(CoffeeImage image);
  Future<List<CoffeeImage>> fetchBatch(int count);
}
