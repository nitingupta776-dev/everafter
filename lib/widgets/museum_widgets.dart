import 'dart:math' as math;

import 'package:everafter/models/travel_artifact.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:flutter/material.dart';

class PaperScaffold extends StatelessWidget {
  const PaperScaffold({
    required this.child,
    this.includeDust = false,
    this.backgroundAsset,
    super.key,
  });

  final Widget child;
  final bool includeDust;
  final String? backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: EverAfterColors.paper),
          if (backgroundAsset case final asset?)
            asset == WarmLinenTexture.assetPath
                ? const WarmLinenTexture(
                    imageKey: ValueKey('warm-linen-background'),
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0x18B98C48),
                      BlendMode.multiply,
                    ),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  )
          else
            const CustomPaint(painter: PaperTexturePainter()),
          if (includeDust) ...const <Widget>[AmbientLight(), AmbientDust()],
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class WarmLinenTexture extends StatelessWidget {
  const WarmLinenTexture({this.imageKey, super.key});

  static const assetPath = 'assets/textures/warm_linen_canvas_visible.jpg';

  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0x18B98C48),
        BlendMode.multiply,
      ),
      child: Image.asset(
        assetPath,
        key: imageKey,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}

class PaperTexturePainter extends CustomPainter {
  const PaperTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = EverAfterColors.catalogLine
      ..strokeWidth = 0.7;
    for (var y = 36.0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final speckPaint = Paint()..color = const Color(0x182A2725);
    for (var i = 0; i < 150; i++) {
      final x = (i * 47 % math.max(size.width.floor(), 1)).toDouble();
      final y = (i * 89 % math.max(size.height.floor(), 1)).toDouble();
      final radius = 0.35 + (i % 3) * 0.22;
      canvas.drawCircle(Offset(x, y), radius, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AmbientLight extends StatefulWidget {
  const AmbientLight({super.key});

  @override
  State<AmbientLight> createState() => _AmbientLightState();
}

class _AmbientLightState extends State<AmbientLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: AmbientLightPainter(progress: _controller.value),
      ),
    );
  }
}

class AmbientLightPainter extends CustomPainter {
  const AmbientLightPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * math.pi * 2;
    final center = Offset(
      size.width * (0.46 + math.sin(phase) * 0.08),
      size.height * (0.42 + math.cos(phase * 0.7) * 0.05),
    );
    final radius = math.max(size.width, size.height) * 0.68;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.24),
          EverAfterColors.brass.withValues(alpha: 0.055),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant AmbientLightPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class AmbientDust extends StatefulWidget {
  const AmbientDust({super.key});

  @override
  State<AmbientDust> createState() => _AmbientDustState();
}

class _AmbientDustState extends State<AmbientDust>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: AmbientDustPainter(progress: _controller.value),
        );
      },
    );
  }
}

class AmbientDustPainter extends CustomPainter {
  const AmbientDustPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x33B98C48);
    for (var i = 0; i < 34; i++) {
      final x = (i * 83 % math.max(size.width.floor(), 1)).toDouble();
      final baseY = (i * 61 % math.max(size.height.floor(), 1)).toDouble();
      final drift = math.sin(progress * math.pi * 2 + i) * 13;
      final y = (baseY + progress * 42 + drift) % size.height;
      canvas.drawCircle(Offset(x, y), 1 + (i % 4) * 0.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AmbientDustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class MuseumLabel extends StatelessWidget {
  const MuseumLabel({
    required this.kicker,
    required this.title,
    required this.body,
    this.trailing,
    super.key,
  });

  final String kicker;
  final String title;
  final String body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EverAfterColors.agedPaper.withValues(alpha: 0.72),
        border: Border.all(color: EverAfterColors.ink.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F2A2725),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(kicker.toUpperCase(), style: textTheme.labelSmall),
            const SizedBox(height: 10),
            Text(title, style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(body, style: textTheme.bodyMedium),
            if (trailing != null) ...<Widget>[
              const SizedBox(height: 14),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class MuseumButton extends StatelessWidget {
  const MuseumButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = Text(label.toUpperCase());
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: buttonLabel,
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward, size: 18),
      label: buttonLabel,
    );
  }
}

class ArtifactStage extends StatefulWidget {
  const ArtifactStage({
    required this.artifact,
    this.compact = false,
    super.key,
  });

  final TravelArtifact artifact;
  final bool compact;

  @override
  State<ArtifactStage> createState() => _ArtifactStageState();
}

class _ArtifactStageState extends State<ArtifactStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferredSize = widget.compact ? 220.0 : 420.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        var dimension = preferredSize;
        if (constraints.maxWidth.isFinite) {
          dimension = math.min(dimension, constraints.maxWidth);
        }
        if (constraints.maxHeight.isFinite) {
          dimension = math.min(dimension, constraints.maxHeight);
        }

        return Semantics(
          label: '${widget.artifact.title} rotating museum object',
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: ArtifactStagePainter(
                  artifact: widget.artifact,
                  progress: _controller.value,
                ),
                child: SizedBox.square(dimension: dimension),
              );
            },
          ),
        );
      },
    );
  }
}

class ArtifactStagePainter extends CustomPainter {
  const ArtifactStagePainter({required this.artifact, required this.progress});

  final TravelArtifact artifact;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = math.min(size.width, size.height);
    final spotlight = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.62),
          EverAfterColors.brass.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: shortest * 0.52));
    canvas.drawCircle(center, shortest * 0.5, spotlight);

    final pedestal = Paint()
      ..color = EverAfterColors.ink.withValues(alpha: 0.12);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, shortest * 0.29),
        width: shortest * 0.62,
        height: shortest * 0.12,
      ),
      pedestal,
    );

    final spin = math.sin(progress * math.pi * 2);
    final width = shortest * (0.45 + spin.abs() * 0.08);
    final height = shortest * 0.34;
    final objectRect = Rect.fromCenter(
      center: center + Offset(0, -shortest * 0.03),
      width: width,
      height: height,
    );

    final shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          objectRect.shift(Offset(0, shortest * 0.018)),
          const Radius.circular(14),
        ),
      );
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = EverAfterColors.ink.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final objectPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(objectRect, const Radius.circular(14)),
      );
    canvas.drawPath(
      objectPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: artifact.colors,
        ).createShader(objectRect),
    );
    canvas.drawPath(
      objectPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = EverAfterColors.ink.withValues(alpha: 0.5),
    );

    final skylinePaint = Paint()
      ..color = EverAfterColors.paper.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final baseY = objectRect.bottom - objectRect.height * 0.24;
    final buildingWidth = objectRect.width / 9;
    for (var i = 0; i < 7; i++) {
      final left =
          objectRect.left + objectRect.width * 0.12 + i * buildingWidth;
      final top = baseY - objectRect.height * (0.16 + (i % 3) * 0.08);
      canvas.drawRect(
        Rect.fromLTWH(left, top, buildingWidth * 0.64, baseY - top),
        skylinePaint,
      );
    }
    canvas.drawCircle(
      objectRect.center + Offset(width * 0.23, -height * 0.12),
      shortest * 0.035,
      Paint()..color = EverAfterColors.brass.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant ArtifactStagePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.artifact != artifact;
  }
}

class MetadataLine extends StatelessWidget {
  const MetadataLine({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 118,
            child: Text(label.toUpperCase(), style: textTheme.labelSmall),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class CollectionStamp extends StatelessWidget {
  const CollectionStamp({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: EverAfterColors.ink.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(value, style: textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
