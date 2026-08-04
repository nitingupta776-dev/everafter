import 'package:everafter/state/museum_controller.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/museum_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final museum = ref.watch(museumControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return PaperScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            sliver: SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Collection Catalogue', style: textTheme.labelLarge),
                    const SizedBox(height: 14),
                    Text(
                      'Trips as museum artifacts',
                      style: textTheme.displayMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A local-first shelf of souvenirs, each ready to become an exhibit when its tag is read.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: EverAfterColors.warmBrown,
                      ),
                    ),
                    const SizedBox(height: 18),
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
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 282,
              ),
              itemCount: museum.artifacts.length,
              itemBuilder: (context, index) {
                final artifact = museum.artifacts[index];
                return InkWell(
                  key: ValueKey('collection-${artifact.uid}'),
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    ref
                        .read(museumControllerProvider.notifier)
                        .selectArtifact(artifact.uid);
                    context.go('/intro/${artifact.uid}');
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: EverAfterColors.agedPaper.withValues(alpha: 0.74),
                      border: Border.all(
                        color: EverAfterColors.ink.withValues(alpha: 0.18),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  artifact.accessionNumber,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall,
                                ),
                              ),
                              const Icon(Icons.nfc, size: 18),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ArtifactStage(
                              artifact: artifact,
                              compact: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            artifact.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${artifact.place} / ${artifact.dateLabel}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: EverAfterColors.warmBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
