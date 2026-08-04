import 'package:everafter/models/travel_artifact.dart';
import 'package:everafter/state/museum_controller.dart';
import 'package:everafter/widgets/museum_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IntroScreen extends ConsumerWidget {
  const IntroScreen({required this.artifact, super.key});

  final TravelArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return PaperScaffold(
      includeDust: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;
                final stage = Hero(
                  tag: 'artifact-${artifact.uid}',
                  child: ArtifactStage(artifact: artifact),
                );
                final label = MuseumLabel(
                  kicker: artifact.accessionNumber,
                  title: artifact.title,
                  body: artifact.coverLine,
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      MetadataLine(label: 'Place', value: artifact.place),
                      MetadataLine(label: 'Date', value: artifact.dateLabel),
                      MetadataLine(label: 'Medium', value: artifact.medium),
                      MetadataLine(label: 'Model', value: artifact.modelAsset),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          MuseumButton(
                            key: const ValueKey('begin-exhibit'),
                            label: 'Tap to begin',
                            icon: Icons.arrow_forward,
                            isPrimary: true,
                            onPressed: () =>
                                context.go('/exhibit/${artifact.uid}'),
                          ),
                          MuseumButton(
                            label: 'Back to idle',
                            icon: Icons.keyboard_return,
                            onPressed: () {
                              ref
                                  .read(museumControllerProvider.notifier)
                                  .returnToIdle();
                              context.go('/');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (!wide) {
                  return Column(
                    children: <Widget>[
                      Text('Artifact Detected', style: textTheme.labelLarge),
                      const SizedBox(height: 10),
                      stage,
                      const SizedBox(height: 22),
                      label,
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    Expanded(child: stage),
                    const SizedBox(width: 48),
                    Expanded(child: label),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
