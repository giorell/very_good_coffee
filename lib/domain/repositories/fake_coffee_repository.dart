// import 'dart:math';
// import 'package:very_good_coffee/domain/entities/coffee_image.dart';
// import 'package:very_good_coffee/domain/repositories/coffee_repository.dart';

// class FakeCoffeeRepository implements CoffeeRepository {
//   final _rng = Random();
//   final _favorites = <CoffeeImage>[];

//   static const _randMax = 1 << 20;

//   String _newId() {
//     final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
//     final r = _rng.nextInt(_randMax);
//     return '$t${r.toRadixString(36)}';
//   }

//   @override
//   Future<CoffeeImage> fetchRandom() async {
//     final id = _newId();
//     final url = Uri.parse('https://picsum.photos/seed/$id/900/1400');
//     return CoffeeImage(id: id, remoteUrl: url);
//   }

//   @override
//   Future<List<CoffeeImage>> fetchBatch(int count) async {
//     return List.generate(count, (_) {
//       final id = _newId();
//       return CoffeeImage(
//         id: id,
//         remoteUrl: Uri.parse('https://picsum.photos/seed/$id/900/1400'),
//       );
//     });
//   }

//   @override
//   Future<void> saveFavorite(CoffeeImage image) async {
//     _favorites.add(image);
//   }

//   List<CoffeeImage> get favorites => List.unmodifiable(_favorites);
// }
