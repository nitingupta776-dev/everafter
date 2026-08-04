import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/ambient_soundtrack.dart';
import 'package:everafter/widgets/pulsing_start_button.dart';
import 'package:everafter/widgets/trip_gallery.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripExperienceRouteData {
  const TripExperienceRouteData({required this.trip, required this.heroTag});

  final TripGalleryItem trip;
  final String heroTag;
}

class TripExperienceScreen extends StatefulWidget {
  const TripExperienceScreen({
    required this.trip,
    required this.heroTag,
    this.onReturnToGallery,
    super.key,
  });

  final TripGalleryItem trip;
  final String heroTag;
  final VoidCallback? onReturnToGallery;

  @override
  State<TripExperienceScreen> createState() => _TripExperienceScreenState();
}

class _TripExperienceScreenState extends State<TripExperienceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _parallaxController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
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
    _parallaxController.dispose();
    _pulseController.dispose();
    _journeyController.dispose();
    super.dispose();
  }

  void _startJourney() {
    if (_journeyStarted) {
      return;
    }
    EverAfterSoundEffects.play(context, EverAfterSoundEffect.globeEntrance);
    setState(() => _journeyStarted = true);
    _parallaxController.stop();
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
    if (context.canPop()) {
      context.pop();
    } else {
      widget.onReturnToGallery?.call();
      context.go('/');
    }
  }

  void _handleRoutePop(bool didPop) {
    if (didPop) {
      widget.onReturnToGallery?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) => _handleRoutePop(didPop),
      child: Scaffold(
        backgroundColor: EverAfterColors.ink,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AnimatedBuilder(
              animation: _journeyController,
              builder: (context, child) {
                final opacity = _journeyStarted
                    ? 1 -
                          Curves.easeInCubic.transform(
                            (_journeyController.value / 0.1).clamp(0, 1),
                          )
                    : 1.0;
                return IgnorePointer(
                  ignoring: _journeyStarted,
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: _buildLanding(textTheme),
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
                      key: const ValueKey('trip-back-to-gallery'),
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

  Widget _buildLanding(TextTheme textTheme) {
    final travelLayout = GalleryLayoutStore.instance.layoutFor(
      widget.trip.slug,
    );
    final dateRangeLabel = travelLayout.effectiveDateRangeLabel(
      widget.trip.dateRangeLabel,
    );
    final durationLabel = travelLayout.effectiveDurationLabel(
      widget.trip.totalDays,
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedBuilder(
          animation: _parallaxController,
          builder: (context, child) {
            final progress = _parallaxController.value;
            return Transform.scale(
              scale: 1.08 + progress * 0.035,
              child: Transform.translate(
                offset: Offset(-10 * progress, -7 * progress),
                child: child,
              ),
            );
          },
          child: Hero(
            tag: widget.heroTag,
            createRectTween: cinematicTripRectTween,
            flightShuttleBuilder: tripImageFlightShuttleBuilder,
            child: TripHeroImage(trip: widget.trip, fullBleed: true),
          ),
        ),
        const ColoredBox(color: Color(0x260B0908)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x280B0908),
                Color(0x140B0908),
                Color(0xC50B0908),
              ],
              stops: <double>[0, 0.36, 1],
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.trip.name.toUpperCase(),
                      key: const ValueKey('trip-experience-title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        color: Colors.white,
                        fontSize: 88,
                        height: 1,
                        letterSpacing: 5.5,
                        decoration: TextDecoration.none,
                        shadows: <Shadow>[
                          Shadow(
                            color: Color(0x9A000000),
                            blurRadius: 30,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  dateRangeLabel,
                  key: const ValueKey('trip-experience-dates'),
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    letterSpacing: 2.1,
                    shadows: const <Shadow>[
                      Shadow(color: Colors.black, blurRadius: 14),
                    ],
                  ),
                ),
                if (durationLabel case final duration?) ...[
                  const SizedBox(height: 11),
                  Text(
                    duration,
                    key: const ValueKey('trip-experience-total-days'),
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 11,
                      letterSpacing: 2.4,
                      shadows: const <Shadow>[
                        Shadow(color: Colors.black, blurRadius: 12),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 38),
                PulsingStartButton(
                  animation: _pulseController,
                  onPressed: _startJourney,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
