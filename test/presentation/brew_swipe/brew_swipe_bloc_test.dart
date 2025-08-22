import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:very_good_coffee/presentation/brew_swipe/bloc/brew_swipe_bloc.dart';
import 'package:very_good_coffee/domain/repositories/coffee_repository.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';

class MockCoffeeRepository extends Mock implements CoffeeRepository {}

CoffeeImage _img(String id) =>
    CoffeeImage(id: id, remoteUrl: Uri.parse('https://example.com/$id.jpg'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(
      CoffeeImage(
        id: 'dummy',
        remoteUrl: Uri.parse('https://example.com/dummy.jpg'),
      ),
    );
  });
  late MockCoffeeRepository repo;

  setUp(() {
    repo = MockCoffeeRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      CoffeeImage(
        id: 'dummy',
        remoteUrl: Uri.parse('https://example.com/dummy.jpg'),
      ),
    );
  });

  group('BrewSwipeBloc', () {
    blocTest<BrewSwipeBloc, BrewSwipeState>(
      'emits loading then ready with current and buffer on start',
      build: () {
        when(() => repo.fetchBatch(any())).thenAnswer((_) async => [
              _img('a'),
              _img('b'),
              _img('c'),
              _img('d'),
              _img('e'),
              _img('f'),
            ]);
        return BrewSwipeBloc(repo, warm: (_) async {});
      },
      act: (bloc) => bloc.add(const BrewSwipeStarted()),
      expect: () => [
        isA<BrewSwipeState>()
            .having((s) => s.status, 'status', BrewSwipeStatus.loading),
        isA<BrewSwipeState>()
            .having((s) => s.status, 'status', BrewSwipeStatus.ready)
            .having((s) => s.current?.id, 'current', 'a')
            .having((s) => s.buffer.map((e) => e.id).toList(), 'buffer',
                ['b', 'c', 'd', 'e', 'f']),
      ],
    );

    blocTest<BrewSwipeBloc, BrewSwipeState>(
      'save advances and calls repository.saveFavorite',
      build: () {
        when(() => repo.fetchBatch(any())).thenAnswer((_) async => [
              _img('a'),
              _img('b'),
              _img('c'),
              _img('d'),
              _img('e'),
              _img('f'),
            ]);
        when(() => repo.saveFavorite(any())).thenAnswer((_) async {});
        return BrewSwipeBloc(repo, warm: (_) async {});
      },
      act: (bloc) async {
        bloc.add(const BrewSwipeStarted());
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(const BrewSwipeSavePressed());
      },
      verify: (bloc) =>
          verify(() => repo.saveFavorite(any(that: isA<CoffeeImage>())))
              .called(1),
      expect: () => [
        isA<BrewSwipeState>()
            .having((s) => s.status, 'status', BrewSwipeStatus.loading),
        isA<BrewSwipeState>()
            .having((s) => s.status, 'status', BrewSwipeStatus.ready)
            .having((s) => s.current?.id, 'current', 'a'),
        isA<BrewSwipeState>()
            .having((s) => s.status, 'status', BrewSwipeStatus.ready)
            .having((s) => s.current?.id, 'current', 'b'),
      ],
    );

    blocTest<BrewSwipeBloc, BrewSwipeState>(
      'skip advances without saving',
      build: () {
        when(() => repo.fetchBatch(any())).thenAnswer((_) async => [
              _img('a'),
              _img('b'),
              _img('c'),
              _img('d'),
              _img('e'),
              _img('f'),
            ]);
        return BrewSwipeBloc(repo, warm: (_) async {});
      },
      act: (bloc) async {
        bloc.add(const BrewSwipeStarted());
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(const BrewSwipeSkipPressed());
      },
      verify: (bloc) => verifyNever(() => repo.saveFavorite(any())),
      expect: () => [
        isA<BrewSwipeState>()
            .having((s) => s.status, 'status', BrewSwipeStatus.loading),
        isA<BrewSwipeState>()
            .having((s) => s.status, 'status', BrewSwipeStatus.ready)
            .having((s) => s.current?.id, 'current', 'a'),
        isA<BrewSwipeState>()
            .having((s) => s.status, 'status', BrewSwipeStatus.ready)
            .having((s) => s.current?.id, 'current', 'b'),
      ],
    );
  });
}
