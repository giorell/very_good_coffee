import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:very_good_coffee/domain/entities/coffee_image.dart';
import 'package:very_good_coffee/domain/repositories/coffee_repository.dart';

class AlexFlipCoffeeRepository implements CoffeeRepository {
  AlexFlipCoffeeRepository({
    http.Client? client,
    this.baseUrl = 'https://coffee.alexflipnote.dev',
    Box<CoffeeImage>? box,
  })  : _client = client ?? http.Client(),
        _box = box ?? Hive.box<CoffeeImage>('favorites') {
    _favorites
      ..clear()
      ..addAll(_box.values);
  }

  final http.Client _client;
  final String baseUrl;
  final Box<CoffeeImage> _box;

  final List<CoffeeImage> _favorites = <CoffeeImage>[];

  String _idFromUrl(Uri url) {
    final segs = url.pathSegments;
    final last = segs.isNotEmpty ? segs.last : null;
    return (last != null && last.isNotEmpty)
        ? last
        : url.toString().hashCode.toRadixString(36);
  }

  Future<Uri> _fetchRandomUri() async {
    final uri = Uri.parse('$baseUrl/random.json');
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw http.ClientException(
          'GET /random.json failed (${resp.statusCode})', uri);
    }
    final map = json.decode(resp.body) as Map<String, dynamic>;
    final file = map['file'] as String?;
    if (file == null || file.isEmpty) {
      throw StateError('Missing "file" in response');
    }
    return Uri.parse(file);
  }

  @override
  Future<CoffeeImage> fetchRandom() async {
    final imageUri = await _fetchRandomUri();
    return CoffeeImage(id: _idFromUrl(imageUri), remoteUrl: imageUri);
  }

  @override
  Future<List<CoffeeImage>> fetchBatch(int count) async {
    final out = <CoffeeImage>[];
    for (var i = 0; i < count; i++) {
      final uri = await _fetchRandomUri();
      out.add(CoffeeImage(id: _idFromUrl(uri), remoteUrl: uri));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return out;
  }

  @override
  Future<void> saveFavorite(CoffeeImage image) async {
    if (_favorites.any((e) => e.id == image.id)) return;
    _favorites.add(image);
    await _box.put(image.id, image);
  }

  void removeFavoriteById(String id) {
    _favorites.removeWhere((e) => e.id == id);
    _box.delete(id);
  }

  List<CoffeeImage> get favorites => List.unmodifiable(_favorites);
}
