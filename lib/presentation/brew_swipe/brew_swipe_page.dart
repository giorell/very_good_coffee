import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:very_good_coffee/domain/repositories/alexflip_coffee_repository.dart';
import 'package:very_good_coffee/presentation/brew_swipe/bloc/brew_swipe_bloc.dart';
import 'package:very_good_coffee/presentation/brew_swipe/widgets/coffee_card.dart';
import 'package:very_good_coffee/presentation/gallery/gallery_page.dart';

class BrewSwipePage extends StatefulWidget {
  const BrewSwipePage({super.key});

  @override
  State<BrewSwipePage> createState() => _BrewSwipePageState();
}

class _BrewSwipePageState extends State<BrewSwipePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AlexFlipCoffeeRepository(),
      child: BlocProvider(
        create: (context) =>
            BrewSwipeBloc(context.read<AlexFlipCoffeeRepository>())
              ..add(const BrewSwipeStarted()),
        child: Scaffold(
          appBar: AppBar(
            title: Text(_index == 0 ? 'BrewSwipe' : 'Gallery'),
            actions: _index == 0
                ? [
                    IconButton(
                      tooltip: 'Retry',
                      onPressed: () => context
                          .read<BrewSwipeBloc>()
                          .add(const BrewSwipeRetryPressed()),
                      icon: const Icon(Icons.refresh),
                    ),
                  ]
                : null,
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _index,
              children: const [
                _BrewSwipeBody(),
                GalleryPage(),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_cafe),
                label: 'Swipe',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_on),
                label: 'Gallery',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrewSwipeBody extends StatelessWidget {
  const _BrewSwipeBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrewSwipeBloc, BrewSwipeState>(
      builder: (context, state) {
        switch (state.status) {
          case BrewSwipeStatus.initial:
          case BrewSwipeStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case BrewSwipeStatus.error:
            return _ErrorState(message: state.error ?? 'Error');
          case BrewSwipeStatus.ready:
            final current = state.current;
            if (current == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 9 / 14,
                        child: Dismissible(
                          key: Key('coffee_${current.id}'),
                          direction: DismissDirection.horizontal,
                          onDismissed: (dir) {
                            final bloc = context.read<BrewSwipeBloc>();
                            if (dir == DismissDirection.startToEnd) {
                              bloc.add(const BrewSwipeSavePressed());
                            } else {
                              bloc.add(const BrewSwipeSkipPressed());
                            }
                          },
                          background: _SwipeBackground(
                            alignment: Alignment.centerLeft,
                            icon: Icons.favorite,
                            label: 'Save',
                            color: Colors.green,
                          ),
                          secondaryBackground: _SwipeBackground(
                            alignment: Alignment.centerRight,
                            icon: Icons.close,
                            label: 'Skip',
                            color: Colors.red,
                          ),
                          child: CoffeeCard(image: current),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BottomBar(),
                ],
              ),
            );
        }
      },
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BrewSwipeBloc>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionBtn(
          icon: Icons.close,
          label: 'Skip',
          onTap: () => bloc.add(const BrewSwipeSkipPressed()),
        ),
        _ActionBtn(
          icon: Icons.favorite,
          label: 'Save',
          onTap: () => bloc.add(const BrewSwipeSavePressed()),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () =>
              context.read<BrewSwipeBloc>().add(const BrewSwipeRetryPressed()),
          child: const Text('Try again'),
        ),
      ]),
    );
  }
}
