import 'dart:async';
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

class _BrewSwipeBody extends StatefulWidget {
  const _BrewSwipeBody();
  @override
  State<_BrewSwipeBody> createState() => _BrewSwipeBodyState();
}

class _BrewSwipeBodyState extends State<_BrewSwipeBody>
    with SingleTickerProviderStateMixin {
  bool _hintVisible = false;
  bool _hintScheduled = false;
  Timer? _timer;

  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _anim = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
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

            if (!_hintScheduled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _hintScheduled) return;
                setState(() {
                  _hintVisible = true;
                  _hintScheduled = true;
                });
                _timer = Timer(const Duration(seconds: 2), () {
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
                        child: Stack(
                          children: [
                            Center(
                              child: Transform.translate(
                                offset: const Offset(0, 6),
                                child: Transform.scale(
                                  scale: 0.976,
                                  child: const _GreyCard(),
                                ),
                              ),
                            ),
                            Center(
                              child: Transform.translate(
                                offset: const Offset(0, 4),
                                child: Transform.scale(
                                  scale: 0.984,
                                  child: const _GreyCard(),
                                ),
                              ),
                            ),
                            Center(
                              child: Transform.translate(
                                offset: const Offset(0, 2),
                                child: Transform.scale(
                                  scale: _backScale(context),
                                  child: const _GreyCard(),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onHorizontalDragUpdate: (d) {
                                if (_ctrl.isAnimating) return;
                                setState(() => _drag += d.delta.dx);
                              },
                              onHorizontalDragEnd: (d) async {
                                final w = MediaQuery.of(context).size.width;
                                final v = d.velocity.pixelsPerSecond.dx;
                                final threshold = w * 0.25;
                                final dir =
                                    (_drag.abs() > threshold || v.abs() > 600)
                                        ? (_drag > 0 ? 1 : -1)
                                        : 0;
                                if (dir == 0) {
                                  await _animateTo(0);
                                  return;
                                }
                                await _animateAndAdvance(dir);
                              },
                              child: AnimatedBuilder(
                                animation: _ctrl,
                                builder: (context, _) {
                                  final x =
                                      _ctrl.isAnimating ? _anim.value : _drag;
                                  return Transform.translate(
                                    offset: Offset(x, 0),
                                    child: CoffeeCard(
                                        key: ValueKey('front_${current.id}'),
                                        image: current),
                                  );
                                },
                              ),
                            ),
                          ],
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
    _anim = Tween<double>(begin: _drag, end: target)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.reset();
    setState(() {});
    await _ctrl.forward();
    _drag = target;
  }

  Future<void> _animateAndAdvance(int dir) async {
    final w = MediaQuery.of(context).size.width;
    await _animateTo(dir * w);
    final bloc = context.read<BrewSwipeBloc>();
    if (dir > 0) {
      bloc.add(const BrewSwipeSavePressed());
    } else {
      bloc.add(const BrewSwipeSkipPressed());
    }
    _drag = 0;
    _ctrl.value = 0;
    setState(() {});
  }

  double _progress(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final val = _ctrl.isAnimating ? (_anim.value.abs() / w) : (_drag.abs() / w);
    if (val < 0) return 0;
    if (val > 1) return 1;
    return val;
  }

  double _backScale(BuildContext context) {
    final p = _progress(context);
    return (0.992 + 0.008 * p) / 2;
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
        _ActionBtn(
          icon: Icons.close,
          label: 'Skip',
          onTap: onSkip,
        ),
        _ActionBtn(
          icon: Icons.favorite,
          label: 'Save',
          onTap: onSave,
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
            children: const [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _HintPill(
                    icon: Icons.arrow_back,
                    text: 'Swipe left to skip',
                    color: Colors.red,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _HintPill(
                    icon: Icons.arrow_forward,
                    text: 'Swipe right to save',
                    color: Colors.green,
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

class _GreyCard extends StatelessWidget {
  const _GreyCard();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Colors.black45),
        child: SizedBox.expand(),
      ),
    );
  }
}
