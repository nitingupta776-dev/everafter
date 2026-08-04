import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/ambient_soundtrack.dart';
import 'package:everafter/widgets/paper_burn_surface.dart';
import 'package:flutter/material.dart';

class SplashSequence extends StatefulWidget {
  const SplashSequence({
    required this.child,
    this.enabled = true,
    this.dismissRequested = false,
    this.duration = const Duration(seconds: 9),
    super.key,
  });

  final Widget child;
  final bool enabled;
  final bool dismissRequested;
  final Duration duration;

  @override
  State<SplashSequence> createState() => _SplashSequenceState();
}

class _SplashSequenceState extends State<SplashSequence>
    with TickerProviderStateMixin {
  static const double _entryRevealProgress = 0.42;

  late final AnimationController _controller;
  late final AnimationController _exitController;
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _titleReveal;
  late final Animation<double> _subtitleReveal;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _textureScale;
  bool _finished = false;
  bool _awaitingEntry = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      animationBehavior: AnimationBehavior.preserve,
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
      animationBehavior: AnimationBehavior.preserve,
    );
    _exitController.addStatusListener(_finishWhenExitCompletes);
    _backgroundOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.14, curve: Curves.easeOutCubic),
    );
    _titleReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.055, 0.28, curve: Curves.easeInOutCubic),
    );
    _subtitleReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.36, curve: Curves.easeInOutCubic),
    );
    _exitOpacity = CurvedAnimation(
      parent: _exitController,
      curve: Curves.linear,
    );
    _textureScale = Tween<double>(
      begin: 1.035,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.enabled && !widget.dismissRequested) {
      _controller.addListener(_revealEntryWhenReady);
      _controller.forward();
    } else {
      _finished = true;
    }
  }

  @override
  void didUpdateWidget(SplashSequence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dismissRequested && !oldWidget.dismissRequested) {
      _controller.stop();
      _exitController.stop();
      _isExiting = false;
      _finished = true;
    }
  }

  void _revealEntryWhenReady() {
    if (!_awaitingEntry && _controller.value >= _entryRevealProgress) {
      setState(() => _awaitingEntry = true);
    }
  }

  void _finishWhenExitCompletes(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _finished = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_revealEntryWhenReady);
    _exitController.removeStatusListener(_finishWhenExitCompletes);
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _enterMuseum() async {
    if (!_awaitingEntry || _isExiting) {
      return;
    }

    EverAfterSoundEffects.activateAudio(context);
    EverAfterSoundEffects.play(context, EverAfterSoundEffect.splashStart);
    setState(() => _isExiting = true);
    unawaited(_startPaperBurnSound());
    await _exitController.forward();
  }

  Future<void> _startPaperBurnSound() async {
    // Let the short button cue finish before the longer transition crackle
    // starts on the shared sound-effect player.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted || !_isExiting) return;
    EverAfterSoundEffects.play(context, EverAfterSoundEffect.paperBurn);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (!_finished)
          Positioned.fill(
            child: Stack(
              key: const ValueKey('splash-sequence-opacity'),
              fit: StackFit.expand,
              children: <Widget>[
                const ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
                RepaintBoundary(
                  child: _PaperBurnTransition(
                    animation: _exitOpacity,
                    active: _isExiting,
                    child: _SplashArtwork(
                      backgroundOpacity: _backgroundOpacity,
                      textureScale: _textureScale,
                      titleReveal: _titleReveal,
                      subtitleReveal: _subtitleReveal,
                      entryVisible: _awaitingEntry,
                      onEnter: _enterMuseum,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PaperBurnTransition extends StatelessWidget {
  const _PaperBurnTransition({
    required this.animation,
    required this.active,
    required this.child,
  });

  final Animation<double> animation;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return child;
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value.clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipPath(
              clipper: _PaperBurnClipper(progress: progress),
              child: child,
            ),
            IgnorePointer(
              child: paperBurnUsesWebGL
                  ? PaperBurnWebGLSurface(progress: progress)
                  : CustomPaint(
                      painter: _PaperBurnEdgePainter(progress: progress),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PaperBurnGeometry {
  static const double edgeOverscan = 76;

  static int segmentCount(Size size) {
    return math.max(140, (size.width / 5).ceil());
  }

  static double _hash(int value) {
    final x = math.sin(value * 127.1 + 311.7) * 43758.5453123;
    return x - x.floorToDouble();
  }

  static double _smoothNoise(double value, int seed) {
    final lower = value.floor();
    final fraction = value - lower;
    final eased = fraction * fraction * (3 - 2 * fraction);
    final start = _hash(lower + seed * 1013);
    final end = _hash(lower + 1 + seed * 1013);
    return ui.lerpDouble(start, end, eased)! * 2 - 1;
  }

  static double baseY(Size size, double progress) {
    final linearProgress = progress.clamp(0.0, 1.0);
    return size.height - (size.height + edgeOverscan) * linearProgress;
  }

  static double edgeY(Size size, double x, double progress) {
    final width = math.max(size.width, 1);
    final normalizedX = x / width;
    final scale = width / 920;
    final travel = progress * 0.72;

    // Broad pockets give the burn front its torn silhouette. The higher
    // frequencies add paper-fibre detail without changing the overall pace.
    final broad = _smoothNoise(normalizedX * 5.2 + travel, 3) * 15;
    final medium = _smoothNoise(normalizedX * 15.7 - travel * 1.3, 11) * 7;
    final fibres = _smoothNoise(normalizedX * 48.0 + travel * 2.1, 29) * 4;
    final singe = _smoothNoise(normalizedX * 113.0 - travel * 3.7, 47) * 1.8;
    final scallopNoise = _smoothNoise(normalizedX * 22.0 + progress * 0.45, 67);
    final scallops = math.pow(math.max(0.0, scallopNoise), 2.4) * 11;

    return baseY(size, progress) +
        (broad + medium + fibres + singe + scallops) * scale.clamp(0.72, 1.2);
  }

  static Path edgePath(Size size, double progress) {
    final path = Path();
    final segments = segmentCount(size);
    for (var index = 0; index <= segments; index++) {
      final x = size.width * index / segments;
      final y = edgeY(size, x, progress);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }
}

class _PaperBurnClipper extends CustomClipper<Path> {
  const _PaperBurnClipper({required this.progress});

  final double progress;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(
        size.width,
        _PaperBurnGeometry.edgeY(size, size.width, progress),
      );

    final segments = _PaperBurnGeometry.segmentCount(size);
    for (var index = segments; index >= 0; index--) {
      final x = size.width * index / segments;
      path.lineTo(x, _PaperBurnGeometry.edgeY(size, x, progress));
    }

    return path..close();
  }

  @override
  bool shouldReclip(covariant _PaperBurnClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

class _PaperBurnEdgePainter extends CustomPainter {
  const _PaperBurnEdgePainter({required this.progress});

  final double progress;

  double _random(int index, int salt) {
    final value = math.sin(index * 91.713 + salt * 37.119) * 43758.5453;
    return value - value.floorToDouble();
  }

  Paint _stroke({
    required Color color,
    required double width,
    double blur = 0,
  }) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1 || size.isEmpty) {
      return;
    }

    final baseY = _PaperBurnGeometry.baseY(size, progress);
    if (baseY < -_PaperBurnGeometry.edgeOverscan ||
        baseY > size.height + _PaperBurnGeometry.edgeOverscan) {
      return;
    }

    final edgePath = _PaperBurnGeometry.edgePath(size, progress);
    final heat = math.sin(progress * math.pi).clamp(0.0, 1.0);

    // The splash is the upper sheet. Clip its soft cast shadow to the revealed
    // side so no haze darkens the artwork that has not burned away yet.
    final shadowClip = Path();
    final shadowSegments = _PaperBurnGeometry.segmentCount(size);
    for (var index = 0; index <= shadowSegments; index++) {
      final x = size.width * index / shadowSegments;
      final y = _PaperBurnGeometry.edgeY(size, x, progress);
      if (index == 0) {
        shadowClip.moveTo(x, y);
      } else {
        shadowClip.lineTo(x, y);
      }
    }
    shadowClip
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.save();
    canvas.clipPath(shadowClip);
    canvas.drawPath(
      edgePath.shift(const Offset(0, 15)),
      _stroke(
        color: const Color(0xFF06101D).withValues(alpha: 0.3),
        width: 34,
        blur: 20,
      ),
    );
    canvas.drawPath(
      edgePath.shift(const Offset(0, 7)),
      _stroke(
        color: const Color(0xFF101319).withValues(alpha: 0.38),
        width: 18,
        blur: 9,
      ),
    );
    canvas.restore();

    // Only a narrow charcoal seam remains attached to the paper itself.
    canvas.drawPath(
      edgePath.shift(const Offset(0, -2.5)),
      _stroke(
        color: const Color(0xFF111318).withValues(alpha: 0.9),
        width: 9,
        blur: 2.4,
      ),
    );
    canvas.drawPath(
      edgePath.shift(const Offset(0, -2.8)),
      _stroke(
        color: const Color(0xFF6D6B66).withValues(alpha: 0.72),
        width: 11,
        blur: 3.4,
      ),
    );

    // A wide soft ash bed and two crisp inner lines recreate the luminous,
    // overexposed paper edge in the reference without an orange neon outline.
    canvas.drawPath(
      edgePath.shift(const Offset(0, 0.8)),
      _stroke(
        color: const Color(0xFFF3F1E8).withValues(alpha: 0.96),
        width: 19,
        blur: 5.8,
      ),
    );
    canvas.drawPath(
      edgePath.shift(const Offset(0, 1.8)),
      _stroke(
        color: const Color(0xFFFFFEF8).withValues(alpha: 0.98),
        width: 9.5,
        blur: 2.1,
      ),
    );
    canvas.drawPath(
      edgePath.shift(const Offset(0, 2.6)),
      _stroke(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.98),
        width: 1.15,
      ),
    );

    final paleAshPaint = Paint()
      ..color = const Color(0xFFFFFEF7).withValues(alpha: 0.9);
    final greyAshPaint = Paint()
      ..color = const Color(0xFFB9B8B3).withValues(alpha: 0.72);
    final sootPaint = Paint()
      ..color = const Color(0xFF171A20).withValues(alpha: 0.78);
    final emberGlowPaint = Paint()
      ..color = const Color(0xFFFFD18B).withValues(alpha: 0.22 * heat)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    final emberCorePaint = Paint()
      ..color = const Color(0xFFFFF4D7).withValues(alpha: 0.54 * heat);
    final paleAshPath = Path();
    final greyAshPath = Path();
    final sootPath = Path();

    // A near-edge cloud of sub-pixel fibres removes the mechanically smooth
    // contour and creates the dense, cottony breakup visible in the target.
    final microFibreCount = math.max(900, (size.width * 0.9).round());
    for (var index = 0; index < microFibreCount; index++) {
      final x = _random(index, 41) * size.width;
      final edgeY = _PaperBurnGeometry.edgeY(size, x, progress);
      final distance = math.pow(_random(index, 42), 1.85) * 28;
      final y = edgeY + 3 - distance;
      if (y < -30 || y > size.height + 20) continue;

      final radius = 0.18 + _random(index, 43) * 0.86;
      final oval = Rect.fromCenter(
        center: Offset(x, y),
        width: radius * (1.2 + _random(index, 44) * 2.2),
        height: radius * (0.65 + _random(index, 45) * 0.8),
      );
      (_random(index, 46) > 0.34 ? paleAshPath : greyAshPath).addOval(oval);
    }

    // Hundreds of stable, seeded fragments build the fuzzy paper-fibre halo.
    // Their density falls off rapidly away from the edge, as in the reference.
    final detailCount = math.max(360, (size.width / 2).round());
    for (var index = 0; index < detailCount; index++) {
      final x = _random(index, 1) * size.width;
      final edgeY = _PaperBurnGeometry.edgeY(size, x, progress);
      final spread = math.pow(_random(index, 2), 2.3) * 54;
      final y = edgeY - 1 - spread + math.sin(progress * 3 + index) * 0.55;
      if (y < -48 || y > size.height + 20) continue;

      final radius = 0.3 + _random(index, 3) * 2.2;
      final tone = _random(index, 4);
      if (tone > 0.2) {
        final oval = Rect.fromCenter(
          center: Offset(x, y),
          width: radius * (1.1 + _random(index, 5) * 2.8),
          height: radius * (0.65 + _random(index, 10) * 0.7),
        );
        (tone > 0.48 ? paleAshPath : greyAshPath).addOval(oval);
      } else {
        sootPath.addOval(
          Rect.fromCircle(center: Offset(x, y), radius: radius * 0.68),
        );
      }
    }

    // Larger clumps sit directly on the rim and make its thickness irregular.
    final clumpCount = math.max(220, (size.width / 3).round());
    for (var index = 0; index < clumpCount; index++) {
      final x = _random(index, 21) * size.width;
      final edgeY = _PaperBurnGeometry.edgeY(size, x, progress);
      final y = edgeY + (_random(index, 22) - 0.64) * 22;
      final width = 0.8 + _random(index, 23) * 5;
      final height = 0.5 + _random(index, 24) * 3.1;
      final oval = Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
      );
      (_random(index, 25) > 0.18 ? paleAshPath : greyAshPath).addOval(oval);
    }

    // A few dark pinholes bite into the intact paper just below the white rim.
    final pinholeCount = math.max(42, (size.width / 24).round());
    for (var index = 0; index < pinholeCount; index++) {
      final x = _random(index, 31) * size.width;
      final edgeY = _PaperBurnGeometry.edgeY(size, x, progress);
      final y = edgeY + 2 + _random(index, 32) * 8;
      final radius = 0.3 + _random(index, 33) * 0.8;
      greyAshPath.addOval(
        Rect.fromCircle(center: Offset(x, y), radius: radius),
      );
    }

    canvas.drawPath(sootPath, sootPaint);
    canvas.drawPath(greyAshPath, greyAshPaint);
    canvas.drawPath(paleAshPath, paleAshPaint);

    // The target has only isolated, faint sparks rather than a continuous fire.
    const emberCount = 8;
    for (var index = 0; index < emberCount; index++) {
      final phase = (progress * (0.12 + _random(index, 8) * 0.08)) % 1.0;
      final x =
          ((_random(index, 6) + phase * 0.035) % 1.0) * size.width +
          math.sin(index * 2.7 + progress * 5) * 2;
      final edgeY = _PaperBurnGeometry.edgeY(size, x, progress);
      final lift = 14 + _random(index, 7) * 48 + phase * 8;
      final y = edgeY - lift;
      if (y < -24 || y > size.height + 20) continue;

      final radius = 0.45 + _random(index, 9) * 0.7;
      canvas.drawCircle(Offset(x, y), radius * 2, emberGlowPaint);
      canvas.drawCircle(Offset(x, y), radius * 0.62, emberCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperBurnEdgePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SplashArtwork extends StatelessWidget {
  const _SplashArtwork({
    required this.backgroundOpacity,
    required this.textureScale,
    required this.titleReveal,
    required this.subtitleReveal,
    required this.entryVisible,
    required this.onEnter,
  });

  final Animation<double> backgroundOpacity;
  final Animation<double> textureScale;
  final Animation<double> titleReveal;
  final Animation<double> subtitleReveal;
  final bool entryVisible;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF27211B),
      child: FadeTransition(
        key: const ValueKey('splash-background-opacity'),
        opacity: backgroundOpacity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const ColoredBox(color: Color(0xFFF1E5D2)),
            ScaleTransition(
              scale: textureScale,
              child: Image.asset(
                'assets/images/splash_travel_museum.png',
                key: const ValueKey('splash-travel-background'),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Semantics(
                          label: 'EverAfter. A Museum of My Travels.',
                          child: ExcludeSemantics(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                BurnInText(
                                  key: const ValueKey('splash-title-burn'),
                                  text: 'EVERAFTER',
                                  reveal: titleReveal,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    color: EverAfterColors.ink,
                                    fontSize: compact ? 52 : 82,
                                    height: 1,
                                    letterSpacing: compact ? 5.2 : 8.5,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                SizedBox(height: compact ? 20 : 28),
                                BurnInText(
                                  key: const ValueKey('splash-subtitle-burn'),
                                  text: 'A Museum of My Travels',
                                  reveal: subtitleReveal,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'ErraticCursive',
                                    color: EverAfterColors.warmBrown,
                                    fontSize: compact ? 29 : 40,
                                    height: 1.15,
                                    letterSpacing: 0.3,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 38 : 48),
                        IgnorePointer(
                          ignoring: !entryVisible,
                          child: AnimatedOpacity(
                            key: const ValueKey('splash-entry-opacity'),
                            opacity: entryVisible ? 1 : 0,
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            child: OutlinedButton(
                              key: const ValueKey('splash-enter-button'),
                              onPressed: entryVisible ? onEnter : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: EverAfterColors.ink,
                                disabledForegroundColor: EverAfterColors.ink,
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: EverAfterColors.ink.withValues(
                                    alpha: 0.42,
                                  ),
                                ),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.7,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              child: const Text('Tap to enter'),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BurnInText extends StatelessWidget {
  const BurnInText({
    required this.text,
    required this.style,
    required this.reveal,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final String text;
  final TextStyle style;
  final Animation<double> reveal;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        final progress = reveal.value.clamp(0.0, 1.0);
        final glow = math.sin(progress * math.pi).clamp(0.0, 1.0);
        final textWidget = Text(text, textAlign: textAlign, style: style);

        return CustomPaint(
          foregroundPainter: _InkBloomPainter(
            progress: progress,
            color: style.color ?? EverAfterColors.ink,
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => _revealShader(bounds, progress),
                child: textWidget,
              ),
              if (glow > 0.01)
                Opacity(
                  opacity: glow * 0.78,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => _edgeShader(bounds, progress),
                    child: Text(
                      text,
                      textAlign: textAlign,
                      style: style.copyWith(
                        color: EverAfterColors.brass,
                        shadows: <Shadow>[
                          Shadow(
                            color: EverAfterColors.brass.withValues(
                              alpha: 0.48,
                            ),
                            blurRadius: 14,
                          ),
                          Shadow(
                            color: EverAfterColors.warmBrown.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  ui.Shader _revealShader(Rect bounds, double progress) {
    final front = bounds.width * (progress * 1.18 - 0.09);
    final feather = math.max(28.0, bounds.width * 0.085);
    return ui.Gradient.linear(
      Offset(front - feather, 0),
      Offset(front + feather * 0.18, 0),
      const <Color>[
        Colors.white,
        Color(0xE8FFFFFF),
        Color(0x78FFFFFF),
        Colors.transparent,
      ],
      const <double>[0, 0.58, 0.82, 1],
      TileMode.clamp,
    );
  }

  ui.Shader _edgeShader(Rect bounds, double progress) {
    final front = bounds.width * (progress * 1.18 - 0.09);
    final width = math.max(24.0, bounds.width * 0.055);
    return ui.Gradient.linear(
      Offset(front - width, 0),
      Offset(front + width, 0),
      const <Color>[
        Colors.transparent,
        Color(0x80FFFFFF),
        Colors.white,
        Color(0x42FFFFFF),
        Colors.transparent,
      ],
      const <double>[0, 0.34, 0.54, 0.76, 1],
      TileMode.clamp,
    );
  }
}

class _InkBloomPainter extends CustomPainter {
  const _InkBloomPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1 || size.isEmpty) {
      return;
    }

    final intensity = math.sin(progress * math.pi);
    final front = size.width * (progress * 1.18 - 0.09);
    for (var index = 0; index < 13; index++) {
      final phase = index * 1.73 + progress * 8.4;
      final x = front - 16 + math.sin(phase) * (18 + index % 3 * 5);
      final y = (index * 31.0 + math.cos(phase * 0.8) * 10) % size.height;
      if (x < -8 || x > size.width + 8) {
        continue;
      }
      final opacity = intensity * (0.07 + (index % 4) * 0.025);
      final paint = Paint()
        ..color = Color.lerp(
          color,
          EverAfterColors.brass,
          0.45,
        )!.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          1.2 + (index % 3) * 0.9,
        );
      canvas.drawCircle(Offset(x, y), 0.8 + (index % 3) * 0.65, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkBloomPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
