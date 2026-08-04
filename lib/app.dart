import 'dart:math' as math;

import 'package:everafter/routing/app_router.dart';
import 'package:everafter/screens/splash_sequence.dart';
import 'package:everafter/state/museum_controller.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/ambient_soundtrack.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EverAfterApp extends ConsumerWidget {
  const EverAfterApp({this.showSplash = true, super.key});

  final bool showSplash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final hasNfcSelection = ref.watch(
      museumControllerProvider.select(
        (museum) => museum.selectedArtifact != null,
      ),
    );

    return MaterialApp.router(
      title: 'EverAfter',
      debugShowCheckedModeBanner: false,
      theme: EverAfterTheme.light(),
      routerConfig: router,
      builder: (context, child) => EverAfterViewport(
        child: SplashSequence(
          enabled:
              showSplash && !(kIsWeb && Uri.base.path.startsWith('/admin/')),
          dismissRequested: hasNfcSelection,
          child: AmbientSoundtrack(
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class EverAfterViewport extends StatelessWidget {
  const EverAfterViewport({required this.child, super.key});

  static const Size designSize = Size(1280, 800);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EverAfterColors.ink,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widthScale = constraints.maxWidth / designSize.width;
          final heightScale = constraints.maxHeight / designSize.height;
          final scale = math.min(widthScale, heightScale);
          final scaledSize = designSize * scale;

          return Center(
            child: SizedBox(
              width: scaledSize.width,
              height: scaledSize.height,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  minWidth: designSize.width,
                  maxWidth: designSize.width,
                  minHeight: designSize.height,
                  maxHeight: designSize.height,
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      key: const ValueKey('everafter-1280x800-surface'),
                      width: designSize.width,
                      height: designSize.height,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(size: designSize),
                        child: ClipRect(child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
