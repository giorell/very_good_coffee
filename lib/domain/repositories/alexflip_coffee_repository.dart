import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:very_good_coffee/domain/entities/coffee_image.dart';
import 'package:very_good_coffee/domain/repositories/coffee_repository.dart';

class AlexFlipCoffeeRepository implements CoffeeRepository {
  AlexFlipCoffeeRepository(
      {http.Client? client, this.baseUrl = 'https://coffee.alexflipnote.dev'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  final List<CoffeeImage> _favorites = <CoffeeImage>[];

  String _idFromUrl(Uri url) {
    final segs = url.pathSegments;
    final last = segs.isNotEmpty ? segs.last : null;
    if (last != null && last.isNotEmpty) return last;
    return url.toString().hashCode.toRadixString(36);
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
  }

  void removeFavoriteById(String id) {
    _favorites.removeWhere((e) => e.id == id);
  }

  List<CoffeeImage> get favorites => List.unmodifiable(_favorites);
}
