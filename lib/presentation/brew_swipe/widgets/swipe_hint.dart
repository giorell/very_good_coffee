import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:very_good_coffee/presentation/brew_swipe/widgets/hint_pill.dart';

class SwipeHint extends StatelessWidget {
  const SwipeHint({required this.visible});
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
                    child: const HintPill(
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
                    child: HintPill(
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
