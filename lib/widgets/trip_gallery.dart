import 'dart:math' as math;

import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/ambient_soundtrack.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class TripGalleryItem {
  const TripGalleryItem({
    required this.number,
    required this.name,
    required this.assetPath,
    this.startDateLabel,
    this.endDateLabel,
    this.totalDays,
    required this.latitude,
    required this.longitude,
  });

  final int number;
  final String name;
  final String assetPath;
  final String? startDateLabel;
  final String? endDateLabel;
  final int? totalDays;
  final double latitude;
  final double longitude;

  String get slug => name.toLowerCase().replaceAll(' ', '-');

  String get portraitAssetPath => assetPath;

  String get dateRangeLabel {
    final start = startDateLabel;
    final end = endDateLabel;
    return start != null && end != null
        ? '$start  →  $end'
        : 'DATES TO BE ADDED';
  }

  String? get durationLabel => switch (totalDays) {
    final days? => '$days DAYS',
    null => null,
  };
}

const List<TripGalleryItem> tripGalleryItems = <TripGalleryItem>[
  TripGalleryItem(
    number: 1,
    name: 'Japan',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 35.6762,
    longitude: 139.6503,
  ),
  TripGalleryItem(
    number: 5,
    name: 'South Korea',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 37.5665,
    longitude: 126.9780,
  ),
  TripGalleryItem(
    number: 2,
    name: 'China',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 39.9042,
    longitude: 116.4074,
  ),
  TripGalleryItem(
    number: 6,
    name: 'Philippines',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 14.5995,
    longitude: 120.9842,
  ),
  TripGalleryItem(
    number: 3,
    name: 'Turkey',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 41.0082,
    longitude: 28.9784,
  ),
  TripGalleryItem(
    number: 7,
    name: 'Taiwan',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 25.0330,
    longitude: 121.5654,
  ),
  TripGalleryItem(
    number: 4,
    name: 'Hong Kong',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 22.3193,
    longitude: 114.1694,
  ),
  TripGalleryItem(
    number: 8,
    name: 'Thailand',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 13.7563,
    longitude: 100.5018,
  ),
  TripGalleryItem(
    number: 9,
    name: 'Malaysia',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 3.1390,
    longitude: 101.6869,
  ),
  TripGalleryItem(
    number: 10,
    name: 'Bali',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: -8.4095,
    longitude: 115.1889,
  ),
  TripGalleryItem(
    number: 11,
    name: 'Vietnam',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 15.8801,
    longitude: 108.3380,
  ),
  TripGalleryItem(
    number: 12,
    name: 'Sri Lanka',
    assetPath: publicMemoryPlaceholderAsset,
    latitude: 7.9570,
    longitude: 80.7603,
  ),
];

class TripGallery extends StatefulWidget {
  const TripGallery({
    required this.controller,
    required this.onTripTap,
    this.autoScrollEnabled = true,
    super.key,
  });

  static const int visibleColumns = 4;
  static const int rowCount = 2;
  static const double columnSpacing = 18;
  static const double autoScrollPixelsPerSecond = 12;

  final ScrollController controller;
  final void Function(TripGalleryItem trip, String heroTag) onTripTap;
  final bool autoScrollEnabled;

  @override
  State<TripGallery> createState() => _TripGalleryState();
}

class _TripGalleryState extends State<TripGallery>
    with SingleTickerProviderStateMixin {
  static const int _loopCopies = 4;

  late final Ticker _autoScrollTicker;
  Duration? _lastTick;
  double? _cycleExtent;

  @override
  void initState() {
    super.initState();
    _autoScrollTicker = createTicker(_handleAutoScroll);
    if (widget.autoScrollEnabled) {
      _autoScrollTicker.start();
    }
  }

  @override
  void didUpdateWidget(covariant TripGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoScrollEnabled == widget.autoScrollEnabled) return;

    _lastTick = null;
    if (widget.autoScrollEnabled) {
      _autoScrollTicker.start();
    } else {
      _autoScrollTicker.stop();
    }
  }

  @override
  void dispose() {
    _autoScrollTicker.dispose();
    super.dispose();
  }

  void _handleAutoScroll(Duration elapsed) {
    final lastTick = _lastTick;
    _lastTick = elapsed;
    if (lastTick == null ||
        !widget.controller.hasClients ||
        _cycleExtent == null) {
      return;
    }

    final position = widget.controller.position;
    if (!position.hasContentDimensions || position.isScrollingNotifier.value) {
      return;
    }

    final deltaSeconds =
        (elapsed.inMicroseconds - lastTick.inMicroseconds) /
        Duration.microsecondsPerSecond;
    final nextOffset =
        position.pixels + TripGallery.autoScrollPixelsPerSecond * deltaSeconds;
    final cycleExtent = _cycleExtent!;
    final wrappedOffset = nextOffset >= cycleExtent * 2
        ? nextOffset - cycleExtent
        : nextOffset;

    widget.controller.jumpTo(
      wrappedOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth -
                TripGallery.columnSpacing * (TripGallery.visibleColumns - 1)) /
            TripGallery.visibleColumns;
        final galleryItemCount = tripGalleryItems.length;
        final columnsPerCycle = (galleryItemCount / TripGallery.rowCount)
            .ceil();
        _cycleExtent =
            columnsPerCycle * (cardWidth + TripGallery.columnSpacing);

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const <PointerDeviceKind>{
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: Scrollbar(
            controller: widget.controller,
            thumbVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: GridView.builder(
              key: const ValueKey('trip-gallery'),
              controller: widget.controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: TripGallery.rowCount,
                mainAxisSpacing: TripGallery.columnSpacing,
                crossAxisSpacing: 14,
                mainAxisExtent: cardWidth,
              ),
              itemCount: galleryItemCount * _loopCopies,
              itemBuilder: (context, index) {
                final localIndex = index % galleryItemCount;
                final trip = tripGalleryItems[localIndex];
                final heroTag = 'trip-gallery-$index-${trip.slug}';
                final placement = _handPlacedCardVariation(trip.number);
                return Transform.translate(
                  key: ValueKey('trip-card-hand-offset-$index'),
                  offset: placement.offset,
                  child: Transform.rotate(
                    key: ValueKey('trip-card-hand-rotation-$index'),
                    angle: placement.angle,
                    alignment: Alignment.center,
                    child: TripCard(
                      key: ValueKey(
                        'trip-$index-${trip.name.toLowerCase().replaceAll(' ', '-')}',
                      ),
                      trip: trip,
                      heroTag: heroTag,
                      onTap: () => widget.onTripTap(trip, heroTag),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HandPlacedCardVariation {
  const _HandPlacedCardVariation({required this.angle, required this.offset});

  final double angle;
  final Offset offset;
}

_HandPlacedCardVariation _handPlacedCardVariation(int tripNumber) {
  final seed = (tripNumber * 97) + 23;
  final angleUnit = ((seed % 17) - 8) / 8;
  final horizontalUnit = (((seed ~/ 17) % 9) - 4) / 4;
  final verticalUnit = (((seed ~/ 153) % 9) - 4) / 4;
  return _HandPlacedCardVariation(
    angle: angleUnit * 0.026,
    offset: Offset(horizontalUnit * 3, verticalUnit * 3),
  );
}

class TripCard extends StatelessWidget {
  const TripCard({
    required this.trip,
    required this.heroTag,
    required this.onTap,
    super.key,
  });

  final TripGalleryItem trip;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${trip.name} start experience',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            EverAfterSoundEffects.play(
              context,
              EverAfterSoundEffect.tripCardZoom,
            );
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 3, 7, 10),
            child: DecoratedBox(
              key: const ValueKey('trip-card-contact-shadow'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x382A2725),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Color(0x268A6546),
                    blurRadius: 4,
                    spreadRadius: -1,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Hero(
                tag: heroTag,
                createRectTween: cinematicTripRectTween,
                flightShuttleBuilder: tripImageFlightShuttleBuilder,
                child: _TripCardFlightCanvas(trip: trip),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

RRect _tripCardImageWindow(Size size) {
  const horizontalPadding = 14.0;
  const topPadding = 12.0;
  const headerHeight = 9.6;
  const headerGap = 7.0;
  const labelHeight = 42.0;
  const bottomPadding = 13.0;
  const sideContentWidth = 50.0;
  const frameAspectRatio = 0.78;
  const imageInset = 4.0;

  final rowTop = topPadding + headerHeight + headerGap;
  final rowBottom = size.height - bottomPadding - labelHeight;
  final rowHeight = math.max(0.0, rowBottom - rowTop);
  final availableWidth = math.max(
    0.0,
    size.width - horizontalPadding * 2 - sideContentWidth,
  );
  final frameWidth = math.min(availableWidth, rowHeight * frameAspectRatio);
  final frameHeight = frameWidth / frameAspectRatio;
  final frameRect = Rect.fromLTWH(
    (size.width - frameWidth) / 2,
    rowTop + (rowHeight - frameHeight) / 2,
    frameWidth,
    frameHeight,
  );
  final imageRect = frameRect.deflate(imageInset);
  final archRadius = math.min(66.0, imageRect.width / 2);

  return RRect.fromRectAndCorners(
    imageRect,
    topLeft: Radius.circular(archRadius),
    topRight: Radius.circular(archRadius),
    bottomLeft: const Radius.circular(1),
    bottomRight: const Radius.circular(1),
  );
}

class _TripCardChromePainter extends CustomPainter {
  const _TripCardChromePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    final windowPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outerPath, Offset.zero)
      ..addRRect(_tripCardImageWindow(size));

    canvas.drawShadow(outerPath, const Color(0x182A2725), 7, true);
    canvas.drawPath(windowPath, Paint()..color = EverAfterColors.paper);
    canvas.drawPath(
      outerPath,
      Paint()
        ..color = EverAfterColors.ink.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_TripCardChromePainter oldDelegate) => false;
}

class _TripCardChrome extends StatelessWidget {
  const _TripCardChrome({required this.trip, this.includePaperTexture = true});

  final TripGalleryItem trip;
  final bool includePaperTexture;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const CustomPaint(painter: _TripCardChromePainter()),
        if (includePaperTexture)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Opacity(
              opacity: 0.34,
              child: Image(
                key: ValueKey('trip-card-paper-texture'),
                image: AssetImage('assets/textures/texturelabs_paper_320.jpg'),
                fit: BoxFit.cover,
                color: Color(0xFFE0CBA7),
                colorBlendMode: BlendMode.multiply,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          child: Column(
            children: <Widget>[
              _TripCardHeader(trip: trip),
              const SizedBox(height: 7),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const _TripCardSparkle(),
                    const SizedBox(width: 12),
                    const Flexible(child: _ArchedTripFrame()),
                    const SizedBox(width: 12),
                    const _TripCardSparkle(),
                  ],
                ),
              ),
              _TripCardLabel(trip: trip),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripCardHeader extends StatelessWidget {
  const _TripCardHeader({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: EverAfterColors.ink.withValues(alpha: 0.62),
      fontSize: 8,
    );
    return Row(
      children: <Widget>[
        Text('TRIP ${trip.number.toString().padLeft(2, '0')}', style: style),
        const Spacer(),
        Text('EVERAFTER', style: style),
      ],
    );
  }
}

class _TripCardSparkle extends StatelessWidget {
  const _TripCardSparkle();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: 13,
      color: EverAfterColors.warmBrown.withValues(alpha: 0.58),
    );
  }
}

class _ArchedTripFrame extends StatelessWidget {
  const _ArchedTripFrame();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.78,
      child: DecoratedBox(
        key: const ValueKey('trip-card-frame-shadow'),
        decoration: BoxDecoration(
          border: Border.all(
            color: EverAfterColors.ink.withValues(alpha: 0.56),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(70),
            bottom: Radius.circular(2),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x302A2725),
              blurRadius: 7,
              spreadRadius: 1,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCardLabel extends StatelessWidget {
  const _TripCardLabel({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EverAfterColors.paper.withValues(alpha: 0.78),
          border: Border.all(
            color: EverAfterColors.ink.withValues(alpha: 0.54),
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 42,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 12),
              const Icon(Icons.diamond, size: 10),
              Expanded(
                child: Text(
                  trip.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    color: EverAfterColors.ink,
                    fontSize: 23,
                    height: 1,
                    letterSpacing: 1.1,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const Icon(Icons.diamond, size: 10),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCardFlightCanvas extends StatelessWidget {
  const _TripCardFlightCanvas({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _TripCardChrome(trip: trip),
        _TripCardImageCanvas(trip: trip),
      ],
    );
  }
}

class _TripCardImageCanvas extends StatelessWidget {
  const _TripCardImageCanvas({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        children: <Widget>[
          Opacity(opacity: 0, child: _TripCardHeader(trip: trip)),
          const SizedBox(height: 7),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(width: 25),
                Flexible(
                  child: AspectRatio(
                    aspectRatio: 0.78,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: TripHeroImage(trip: trip),
                    ),
                  ),
                ),
                const SizedBox(width: 25),
              ],
            ),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }
}

class TripHeroImage extends StatelessWidget {
  const TripHeroImage({required this.trip, this.fullBleed = false, super.key});

  final TripGalleryItem trip;
  final bool fullBleed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: fullBleed
          ? BorderRadius.zero
          : const BorderRadius.vertical(
              top: Radius.circular(66),
              bottom: Radius.circular(1),
            ),
      child: Image.asset(
        trip.assetPath,
        fit: BoxFit.cover,
        alignment: fullBleed ? Alignment.center : const Alignment(0, -0.08),
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

Widget tripImageFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final fromHeroChild = (fromHeroContext.widget as Hero).child;
  final toHeroChild = (toHeroContext.widget as Hero).child;
  final trip = switch (fromHeroChild) {
    _TripCardFlightCanvas(:final trip) => trip,
    TripHeroImage(:final trip) => trip,
    _ => switch (toHeroChild) {
      _TripCardFlightCanvas(:final trip) => trip,
      TripHeroImage(:final trip) => trip,
      _ => throw StateError('Trip image Hero is missing its trip.'),
    },
  };
  final cardContext = flightDirection == HeroFlightDirection.push
      ? fromHeroContext
      : toHeroContext;
  final cardRect = _globalRectForContext(cardContext);
  final cardSize = cardRect.size;
  final curve = CurvedAnimation(parent: animation, curve: _imageFlightCurve);

  return AnimatedBuilder(
    animation: curve,
    builder: (context, child) {
      // The route animation already runs 0 -> 1 on push and 1 -> 0 on pop.
      // Reusing its value makes the pop flight the exact geometric reverse.
      final progress = curve.value;
      final borderRadius = BorderRadius.lerp(
        const BorderRadius.vertical(
          top: Radius.circular(66),
          bottom: Radius.circular(1),
        ),
        BorderRadius.zero,
        progress,
      )!;
      final alignment = Alignment.lerp(
        const Alignment(0, -0.08),
        Alignment.center,
        progress,
      )!;
      final frameProgress = _frameFlightCurve.transform(animation.value);
      return LayoutBuilder(
        builder: (context, constraints) {
          final flightSize = constraints.biggest;
          final flightRect = Offset.zero & flightSize;
          final fittedFrameSize = applyBoxFit(
            BoxFit.contain,
            cardSize,
            flightSize,
          ).destination;
          final visibleFrameRect = Alignment.center.inscribe(
            fittedFrameSize,
            flightRect,
          );
          final frameScale = visibleFrameRect.width / cardSize.width;
          final cardWindow = _tripCardImageWindow(cardSize);
          final windowRect = Rect.fromLTWH(
            visibleFrameRect.left + cardWindow.left * frameScale,
            visibleFrameRect.top + cardWindow.top * frameScale,
            cardWindow.width * frameScale,
            cardWindow.height * frameScale,
          );
          final windowRRect = RRect.fromRectAndCorners(
            windowRect,
            topLeft: cardWindow.tlRadius * frameScale,
            topRight: cardWindow.trRadius * frameScale,
            bottomLeft: cardWindow.blRadius * frameScale,
            bottomRight: cardWindow.brRadius * frameScale,
          );
          final frameExitScale = _tripFrameExitScale(frameProgress);
          final clipRRect = _scaleRRectAroundCenter(
            windowRRect,
            frameExitScale,
            flightRect.center,
          );
          final expandedImageRect = Rect.lerp(
            windowRRect.outerRect,
            flightRect,
            progress,
          )!.expandToInclude(clipRRect.outerRect);
          final flightProgress = animation.value;
          final handoffProgress = const Interval(
            0.86,
            1,
            curve: Curves.easeInOutCubic,
          ).transform(flightProgress);
          final imageContentRect = Rect.lerp(
            expandedImageRect,
            flightRect,
            handoffProgress,
          )!;

          return Stack(
            key: const ValueKey('trip-flight-unit'),
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: ClipPath(
                  key: const ValueKey('trip-flight-window'),
                  clipper: _TripFlightWindowClipper(clipRRect),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned.fromRect(
                        rect: imageContentRect,
                        child: ClipRRect(
                          key: const ValueKey('trip-flight-image'),
                          borderRadius: borderRadius,
                          child: Image.asset(
                            trip.assetPath,
                            fit: BoxFit.cover,
                            alignment: alignment,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: visibleFrameRect,
                child: Transform.scale(
                  key: const ValueKey('trip-flight-frame-expansion'),
                  scale: frameExitScale,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox.fromSize(
                      size: cardSize,
                      child: _TripCardChrome(
                        trip: trip,
                        includePaperTexture: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Rect _globalRectForContext(BuildContext context) {
  final renderBox = context.findRenderObject();
  if (renderBox is! RenderBox || !renderBox.hasSize) {
    return Offset.zero & const Size(1280, 800);
  }

  return renderBox.localToGlobal(Offset.zero) & renderBox.size;
}

class _TripFlightWindowClipper extends CustomClipper<Path> {
  const _TripFlightWindowClipper(this.window);

  final RRect window;

  @override
  Path getClip(Size size) => Path()..addRRect(window);

  @override
  bool shouldReclip(_TripFlightWindowClipper oldClipper) =>
      oldClipper.window != window;
}

double _tripFrameExitScale(double progress) => 1 + 2.1 * progress;

RRect _scaleRRectAroundCenter(RRect source, double scale, Offset center) {
  final scaledRect = Rect.fromCenter(
    center: center + (source.center - center) * scale,
    width: source.width * scale,
    height: source.height * scale,
  );

  return RRect.fromRectAndCorners(
    scaledRect,
    topLeft: source.tlRadius * scale,
    topRight: source.trRadius * scale,
    bottomLeft: source.blRadius * scale,
    bottomRight: source.brRadius * scale,
  );
}

const Curve _imageFlightCurve = Interval(
  0,
  0.62,
  curve: Cubic(0.12, 0.72, 0.18, 1),
);
// A symmetric cinematic ease keeps the card attached to its starting frame,
// accelerates through the middle of the flight, and settles into the trip
// screen without the previous hard finish. Geometry and frame expansion share
// the same curve so their edges never drift apart.
const Curve _cardFlightCurve = Cubic(0.65, 0, 0.35, 1);
const Curve _frameFlightCurve = _cardFlightCurve;
const Curve _flightPositionCurve = _cardFlightCurve;

RectTween cinematicTripRectTween(Rect? begin, Rect? end) {
  return _CinematicTripRectTween(
    begin: begin,
    end: end,
    positionCurve: _flightPositionCurve,
    // The image and frame share one moving canvas. Image content expands on
    // the faster reveal curve inside the flight shuttle's arched mask.
    scaleCurve: _frameFlightCurve,
  );
}

class _CinematicTripRectTween extends RectTween {
  _CinematicTripRectTween({
    required this.positionCurve,
    required this.scaleCurve,
    super.begin,
    super.end,
  });

  final Curve positionCurve;
  final Curve scaleCurve;

  @override
  Rect lerp(double t) {
    final center = Offset.lerp(
      begin!.center,
      end!.center,
      positionCurve.transform(t),
    )!;
    final size = Size.lerp(begin!.size, end!.size, scaleCurve.transform(t))!;

    return Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
  }
}
