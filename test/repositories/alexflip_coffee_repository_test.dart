import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';
import 'package:very_good_coffee/domain/repositories/alexflip_coffee_repository.dart';

class _MockClient extends Mock implements http.Client {}

class _MockBox extends Mock implements Box<CoffeeImage> {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('AlexFlipCoffeeRepository', () {
    late _MockClient client;
    late _MockBox box;

    setUp(() {
      client = _MockClient();
      box = _MockBox();
      when(() => box.values).thenReturn(const Iterable<CoffeeImage>.empty());
    });

    test('fetchRandom returns CoffeeImage from /random.json', () async {
      final url = Uri.parse('https://coffee.alexflipnote.dev/random.json');
      when(() => client.get(url)).thenAnswer((_) async =>
          http.Response(jsonEncode({'file': 'https://img.test/abc.jpg'}), 200));

      final repo = AlexFlipCoffeeRepository(client: client, box: box);
      final img = await repo.fetchRandom();

      expect(img.remoteUrl.toString(), 'https://img.test/abc.jpg');
      expect(img.id, 'abc.jpg');
      verify(() => client.get(url)).called(1);
    });

    test('fetchRandom throws on non-200', () async {
      final url = Uri.parse('https://coffee.alexflipnote.dev/random.json');
      when(() => client.get(url))
          .thenAnswer((_) async => http.Response('err', 503));

      final repo = AlexFlipCoffeeRepository(client: client, box: box);

      expect(
        () => repo.fetchRandom(),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('fetchBatch returns count items', () async {
      // local counter for unique URLs
      var seq = 0;

      when(() => client.get(any(that: isA<Uri>()))).thenAnswer((_) async {
        final i = seq++;
        return http.Response(
          jsonEncode({'file': 'https://img.test/pic_$i.jpg'}),
          200,
        );
      });

      final repo = AlexFlipCoffeeRepository(client: client, box: box);
      final items = await repo.fetchBatch(5);

      expect(items.length, 5);
      expect(items.map((e) => e.remoteUrl.toString()).toSet().length, 5);

      // Assert total calls (match any Uri)
      verify(() => client.get(any(that: isA<Uri>()))).called(5);
    });

    test('saveFavorite persists to box once and avoids duplicates', () async {
      final repo = AlexFlipCoffeeRepository(client: client, box: box);
      final img = CoffeeImage(id: 'x', remoteUrl: Uri.parse('https://x'));

      when(() => box.put('x', img)).thenAnswer((_) async {});

      await repo.saveFavorite(img);
      await repo.saveFavorite(img);

      expect(repo.favorites.length, 1);
      verify(() => box.put('x', img)).called(1);
    });

    test('removeFavoriteById removes from box and memory', () async {
      final repo = AlexFlipCoffeeRepository(client: client, box: box);
      final img = CoffeeImage(id: 'y', remoteUrl: Uri.parse('https://y'));
      when(() => box.put('y', img)).thenAnswer((_) async {});
      when(() => box.delete('y')).thenAnswer((_) async {});

      await repo.saveFavorite(img);
      expect(repo.favorites.any((e) => e.id == 'y'), isTrue);

      repo.removeFavoriteById('y');
      expect(repo.favorites.any((e) => e.id == 'y'), isFalse);
      verify(() => box.delete('y')).called(1);
    });

    test('loads initial favorites from box on construct', () async {
      final existing = [
        CoffeeImage(id: 'a', remoteUrl: Uri.parse('https://a')),
        CoffeeImage(id: 'b', remoteUrl: Uri.parse('https://b')),
      ];
      when(() => box.values).thenReturn(existing);

      final repo = AlexFlipCoffeeRepository(client: client, box: box);
      expect(repo.favorites, existing);
    });
  });
}
