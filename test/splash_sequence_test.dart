import 'package:everafter/app.dart';
import 'package:everafter/screens/splash_sequence.dart';
import 'package:everafter/widgets/ambient_soundtrack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('entry appears shortly after the subtitle and waits for a tap', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EverAfterApp()));
    await tester.pump();

    final background = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('splash-background-opacity')),
    );
    final title = tester.widget<BurnInText>(
      find.byKey(const ValueKey('splash-title-burn')),
    );
    final subtitle = tester.widget<BurnInText>(
      find.byKey(const ValueKey('splash-subtitle-burn')),
    );

    expect(background.opacity.value, 0);
    expect(title.reveal.value, 0);
    expect(subtitle.reveal.value, 0);
    expect(
      find.byKey(const ValueKey('splash-travel-background')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('splash-entry-opacity')),
          )
          .opacity,
      0,
    );

    await tester.pump(const Duration(milliseconds: 600));
    expect(background.opacity.value, greaterThan(0));
    expect(title.reveal.value, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 700));
    expect(subtitle.reveal.value, greaterThan(0));
    expect(find.text('EVERAFTER'), findsWidgets);
    expect(find.text('A Museum of My Travels'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.byKey(const ValueKey('splash-sequence-opacity')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('splash-entry-opacity')),
          )
          .opacity,
      1,
    );
    expect(find.text('Tap to enter'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    expect(
      find.byKey(const ValueKey('splash-sequence-opacity')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('splash-enter-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const ValueKey('splash-sequence-opacity')),
      findsOneWidget,
    );
    expect(find.byType(ClipPath), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2700));
    expect(
      find.byKey(const ValueKey('splash-sequence-opacity')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('splash-sequence-opacity')), findsNothing);
    expect(find.text('MUSEUM OF TRAVELS'), findsOneWidget);
  });

  testWidgets('entry tap requests its cue then the fire crackle effect', (
    tester,
  ) async {
    final requestedEffects = <EverAfterSoundEffect>[];
    var audioActivated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EverAfterSoundEffects(
          onPlay: requestedEffects.add,
          onActivateAudio: () => audioActivated = true,
          child: const SplashSequence(
            duration: Duration(milliseconds: 100),
            child: ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('splash-enter-button')));
    await tester.pump();

    expect(audioActivated, isTrue);
    expect(requestedEffects, <EverAfterSoundEffect>[
      EverAfterSoundEffect.splashStart,
    ]);

    await tester.pump(const Duration(milliseconds: 220));

    expect(requestedEffects, <EverAfterSoundEffect>[
      EverAfterSoundEffect.splashStart,
      EverAfterSoundEffect.paperBurn,
    ]);

    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump();
  });
}
