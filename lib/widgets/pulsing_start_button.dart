import 'dart:math' as math;

import 'package:flutter/material.dart';

class PulsingStartButton extends StatelessWidget {
  const PulsingStartButton({
    required this.animation,
    required this.onPressed,
    super.key,
  });

  final Animation<double> animation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('pulsing-start-button'),
      dimension: 138,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              _PulseRing(progress: animation.value),
              _PulseRing(progress: (animation.value + 0.5) % 1),
              child!,
            ],
          );
        },
        child: OutlinedButton(
          key: const ValueKey('start-trip-experience'),
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black.withValues(alpha: 0.08),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.82),
              width: 1.2,
            ),
            fixedSize: const Size.square(100),
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              letterSpacing: 2.4,
              decoration: TextDecoration.none,
            ),
          ),
          child: const Text('START'),
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress);
    final opacity = math.max(0.0, (1 - eased) * 0.42);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: 1 + eased * 0.34,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: const SizedBox.square(dimension: 100),
        ),
      ),
    );
  }
}
