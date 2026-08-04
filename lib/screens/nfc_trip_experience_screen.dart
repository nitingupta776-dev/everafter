import 'dart:ui';

import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/ambient_soundtrack.dart';
import 'package:everafter/widgets/pulsing_start_button.dart';
import 'package:everafter/widgets/trip_gallery.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NfcTripExperienceScreen extends StatefulWidget {
  const NfcTripExperienceScreen({
    required this.trip,
    required this.magnetAssetPath,
    required this.onReturnToGallery,
    super.key,
  });

  final TripGalleryItem trip;
  final String magnetAssetPath;
  final VoidCallback onReturnToGallery;

  @override
  State<NfcTripExperienceScreen> createState() =>
      _NfcTripExperienceScreenState();
}

class _NfcTripExperienceScreenState extends State<NfcTripExperienceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat(reverse: true);
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final AnimationController _journeyController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 8200),
  );
  final GlobalKey<TripJourneyState> _tripJourneyKey =
      GlobalKey<TripJourneyState>();
  bool _journeyStarted = false;

  @override
  void dispose() {
    _revealController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _journeyController.dispose();
    super.dispose();
  }

  void _startJourney() {
    if (_journeyStarted) return;

    EverAfterSoundEffects.play(context, EverAfterSoundEffect.globeEntrance);
    setState(() => _journeyStarted = true);
    _glowController.stop();
    _pulseController.stop();
    _journeyController.forward(from: 0);
  }

  Future<void> _returnToGallery() async {
    if (await _tripJourneyKey.currentState?.dismissFocusedMemoryIfNeeded() ??
        false) {
      return;
    }
    if (!mounted) {
      return;
    }
    EverAfterSoundEffects.play(context, EverAfterSoundEffect.tripCardZoom);
    widget.onReturnToGallery();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onReturnToGallery();
      },
      child: Scaffold(
        backgroundColor: EverAfterColors.ink,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _revealController,
                _journeyController,
              ]),
              builder: (context, child) {
                final reveal = Curves.easeOutCubic.transform(
                  _revealController.value,
                );
                final exitOpacity = _journeyStarted
                    ? 1 -
                          Curves.easeInCubic.transform(
                            (_journeyController.value / 0.1).clamp(0, 1),
                          )
                    : 1.0;
                return IgnorePointer(
                  ignoring: _journeyStarted,
                  child: Opacity(
                    opacity: reveal * exitOpacity,
                    child: Transform.scale(
                      scale: 1.025 - (0.025 * reveal),
                      child: child,
                    ),
                  ),
                );
              },
              child: _NfcMagnetLanding(
                trip: widget.trip,
                magnetAssetPath: widget.magnetAssetPath,
                glowAnimation: CurvedAnimation(
                  parent: _glowController,
                  curve: Curves.easeInOutSine,
                ),
                startAnimation: _pulseController,
                onStart: _startJourney,
              ),
            ),
            if (_journeyStarted)
              TripJourney(
                key: _tripJourneyKey,
                trip: widget.trip,
                animation: _journeyController,
                onTasteTap: () async {
                  await context.push<void>('/taste/${widget.trip.slug}');
                },
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 20),
                  child: Material(
                    color: const Color(0x70161210),
                    shape: const CircleBorder(),
                    child: IconButton(
                      key: const ValueKey('nfc-back-to-gallery'),
                      tooltip: 'Back to travel gallery',
                      onPressed: _returnToGallery,
                      color: EverAfterColors.paper,
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NfcMagnetLanding extends StatelessWidget {
  const _NfcMagnetLanding({
    required this.trip,
    required this.magnetAssetPath,
    required this.glowAnimation,
    required this.startAnimation,
    required this.onStart,
  });

  final TripGalleryItem trip;
  final String magnetAssetPath;
  final Animation<double> glowAnimation;
  final Animation<double> startAnimation;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('nfc-magnet-reveal'),
      fit: StackFit.expand,
      children: <Widget>[
        Semantics(
          image: true,
          label: '${trip.name} travel magnet',
          child: Image.asset(
            magnetAssetPath,
            key: const ValueKey('nfc-magnet-image'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
        AnimatedBuilder(
          animation: glowAnimation,
          builder: (context, child) {
            final pulse = glowAnimation.value;
            return IgnorePointer(
              child: Opacity(
                key: const ValueKey('nfc-glow-pulse'),
                opacity: 0.08 + (pulse * 0.16),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 0.8 + (pulse * 1.4),
                    sigmaY: 0.8 + (pulse * 1.4),
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const RadialGradient(
              center: Alignment(0, -0.06),
              radius: 0.56,
              colors: <Color>[Colors.white, Colors.white, Color(0x00FFFFFF)],
              stops: <double>[0, 0.46, 1],
            ).createShader(bounds),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFFFFD28B),
                BlendMode.screen,
              ),
              child: Image.asset(
                magnetAssetPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 30, 40, 36),
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x991D1713),
                      border: Border.all(
                        color: EverAfterColors.brass.withValues(alpha: 0.72),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      child: Text(
                        'NFC MEMORY FOUND',
                        key: ValueKey('nfc-detected-label'),
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: EverAfterColors.paper,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: _TripName(trip: trip),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: _TripDetails(trip: trip),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: PulsingStartButton(
            animation: startAnimation,
            onPressed: onStart,
          ),
        ),
      ],
    );
  }
}

class _TripName extends StatelessWidget {
  const _TripName({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    final destinationFontSize =
        trip.name.length >= 7 && !trip.name.contains(' ') ? 46.0 : 56.0;

    return SizedBox(
      key: const ValueKey('nfc-trip-name'),
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'DESTINATION',
            style: TextStyle(
              fontFamily: 'Georgia',
              color: Color(0xCCF6F1E8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.2,
              decoration: TextDecoration.none,
              shadows: <Shadow>[
                Shadow(color: Color(0xB8000000), blurRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            trip.name.toUpperCase().replaceAll(' ', '\n'),
            maxLines: trip.name.contains(' ') ? 2 : 1,
            style: TextStyle(
              fontFamily: 'Georgia',
              color: Colors.white,
              fontSize: destinationFontSize,
              height: 0.88,
              letterSpacing: 2.4,
              decoration: TextDecoration.none,
              shadows: <Shadow>[
                Shadow(
                  color: Color(0xC7000000),
                  blurRadius: 22,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'TRIP ${trip.number.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontFamily: 'Georgia',
              color: Color(0xBFF6F1E8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              decoration: TextDecoration.none,
              shadows: <Shadow>[
                Shadow(color: Color(0xB8000000), blurRadius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDetails extends StatelessWidget {
  const _TripDetails({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    final travelLayout = GalleryLayoutStore.instance.layoutFor(trip.slug);
    final startDate = travelLayout.effectiveStartDateLabel(trip.startDateLabel);
    final endDate = travelLayout.effectiveEndDateLabel(trip.endDateLabel);
    final duration = travelLayout.effectiveDurationLabel(trip.totalDays);
    return SizedBox(
      key: const ValueKey('nfc-trip-details'),
      width: 230,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          const Text(
            'TRIP DETAILS',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Georgia',
              color: Color(0xCCF6F1E8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.2,
              decoration: TextDecoration.none,
              shadows: <Shadow>[
                Shadow(color: Color(0xB8000000), blurRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TripDetailLine(label: 'ARRIVED', value: startDate),
          const SizedBox(height: 13),
          _TripDetailLine(label: 'DEPARTED', value: endDate),
          if (duration case final durationLabel?) ...[
            const SizedBox(height: 22),
            Text(
              durationLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: Colors.white,
                fontSize: 31,
                letterSpacing: 2.2,
                decoration: TextDecoration.none,
                shadows: <Shadow>[
                  Shadow(
                    color: Color(0xC7000000),
                    blurRadius: 18,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripDetailLine extends StatelessWidget {
  const _TripDetailLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          label,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Georgia',
            color: Color(0xA6F6F1E8),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
            decoration: TextDecoration.none,
            shadows: <Shadow>[Shadow(color: Color(0xB8000000), blurRadius: 9)],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value ?? 'TO BE ADDED',
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Georgia',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            decoration: TextDecoration.none,
            shadows: <Shadow>[Shadow(color: Color(0xC7000000), blurRadius: 12)],
          ),
        ),
      ],
    );
  }
}
