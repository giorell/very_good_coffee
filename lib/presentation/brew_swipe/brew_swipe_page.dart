import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:very_good_coffee/domain/repositories/alexflip_coffee_repository.dart';
import 'package:very_good_coffee/presentation/brew_swipe/bloc/brew_swipe_bloc.dart';
import 'package:very_good_coffee/presentation/brew_swipe/widgets/coffee_card.dart';
import 'package:very_good_coffee/presentation/gallery/gallery_page.dart';
import 'package:very_good_coffee/presentation/saved/saved_page.dart';
import 'package:hive/hive.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';

class BrewSwipePage extends StatefulWidget {
  const BrewSwipePage({super.key});

  @override
  State<BrewSwipePage> createState() => _BrewSwipePageState();
}

class _BrewSwipePageState extends State<BrewSwipePage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) =>
          AlexFlipCoffeeRepository(box: Hive.box<CoffeeImage>('favorites')),
      child: BlocProvider(
        create: (context) =>
            BrewSwipeBloc(context.read<AlexFlipCoffeeRepository>())
              ..add(const BrewSwipeStarted()),
        child: Scaffold(
          appBar: AppBar(
            title: Text(_selectedTabIndex == 0
                ? 'BrewSwipe'
                : _selectedTabIndex == 1
                    ? 'Gallery'
                    : 'Saved'),
            actions: _selectedTabIndex == 0
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
              index: _selectedTabIndex,
              children: const [
                _BrewSwipeBody(),
                GalleryPage(),
                SavedPage(),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedTabIndex,
            onTap: (i) => setState(() => _selectedTabIndex = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_cafe),
                label: 'Swipe',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_on),
                label: 'Gallery',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_outline),
                label: 'Saved',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrewSwipeBody extends StatefulWidget {
  const _BrewSwipeBody();
  @override
  State<_BrewSwipeBody> createState() => _BrewSwipeBodyState();
}

class _BrewSwipeBodyState extends State<_BrewSwipeBody>
    with SingleTickerProviderStateMixin {
  bool _hintVisible = false;
  bool _isHintScheduled = false;
  Timer? _hintDismissTimer;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  double _dragOffsetX = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hintDismissTimer?.cancel();
    super.dispose();
  }

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
            if (current == null)
              return const Center(child: CircularProgressIndicator());

            if (!_isHintScheduled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _isHintScheduled) return;
                setState(() {
                  _hintVisible = true;
                  _isHintScheduled = true;
                });
                _hintDismissTimer = Timer(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _hintVisible = false);
                });
              });
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
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            if (_animationController.isAnimating) return;
                            setState(() => _dragOffsetX += details.delta.dx);
                          },
                          onHorizontalDragEnd: (details) async {
                            final screenWidth =
                                MediaQuery.of(context).size.width;
                            final velocityX =
                                details.velocity.pixelsPerSecond.dx;
                            final direction =
                                (_dragOffsetX.abs() > screenWidth * 0.25 ||
                                        velocityX.abs() > 600)
                                    ? (_dragOffsetX > 0 ? 1 : -1)
                                    : 0;
                            if (direction == 0) {
                              await _animateTo(0);
                              return;
                            }
                            await _animateAndAdvance(direction);
                          },
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, _) {
                              final translateX =
                                  _animationController.isAnimating
                                      ? _slideAnimation.value
                                      : _dragOffsetX;
                              return Transform.translate(
                                offset: Offset(translateX, 0),
                                child: CoffeeCard(
                                    key: ValueKey('front_${current.id}'),
                                    image: current),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SwipeHint(visible: _hintVisible),
                  const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  _BottomBar(
                      onSkip: () => _animateAndAdvance(-1),
                      onSave: () => _animateAndAdvance(1)),
                ],
              ),
            );
        }
      },
    );
  }

  Future<void> _animateTo(double target) async {
    _slideAnimation = Tween<double>(begin: _dragOffsetX, end: target).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.reset();
    setState(() {});
    await _animationController.forward();
    _dragOffsetX = target;
  }

  Future<void> _animateAndAdvance(int direction) async {
    final screenWidth = MediaQuery.of(context).size.width;
    await _animateTo(direction * screenWidth);
    final bloc = context.read<BrewSwipeBloc>();
    if (direction > 0) {
      bloc.add(const BrewSwipeSavePressed());
    } else {
      bloc.add(const BrewSwipeSkipPressed());
    }
    _dragOffsetX = 0;
    _animationController.value = 0;
    setState(() {});
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
        color: color.withOpacity(0.2),
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
  const _BottomBar({required this.onSkip, required this.onSave});

  final VoidCallback onSkip;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.close,
          label: 'Skip',
          onTap: onSkip,
        ),
        _ActionButton(
          icon: Icons.favorite,
          label: 'Save',
          onTap: onSave,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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

class _HintPill extends StatelessWidget {
  const _HintPill(
      {required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.visible});
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 82),
                    child: const _HintPill(
                      icon: Icons.arrow_back,
                      text: 'Skip',
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 84),
                    child: _HintPill(
                      icon: Icons.arrow_forward,
                      text: 'Save',
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
