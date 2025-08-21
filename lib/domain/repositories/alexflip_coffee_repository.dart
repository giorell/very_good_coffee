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
    // Use the last path segment as ID; fallback to hash if empty
    final name = url.pathSegments.isNotEmpty ? url.pathSegments.last : '';
    return name.isNotEmpty ? name : url.toString().hashCode.toRadixString(36);
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
      final imageUri = await _fetchRandomUri();
      out.add(CoffeeImage(id: _idFromUrl(imageUri), remoteUrl: imageUri));
      // Small delay helps avoid burst traffic
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return out;
  }

  @override
  Future<void> saveFavorite(CoffeeImage image) async {
    // Note: local persistence handled elsewhere; we keep a simple in-memory list here.
    _favorites.add(image);
  }

  List<CoffeeImage> get favorites => List.unmodifiable(_favorites);
}
