import 'package:everafter/models/travel_artifact.dart';
import 'package:everafter/state/museum_controller.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/museum_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExhibitScreen extends ConsumerStatefulWidget {
  const ExhibitScreen({required this.artifact, super.key});

  final TravelArtifact artifact;

  @override
  ConsumerState<ExhibitScreen> createState() => _ExhibitScreenState();
}

class _ExhibitScreenState extends ConsumerState<ExhibitScreen> {
  late final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artifact = widget.artifact;
    final textTheme = Theme.of(context).textTheme;

    return PaperScaffold(
      includeDust: true,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${artifact.place} / ${artifact.dateLabel}',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Collection',
                  onPressed: () => context.go('/collection'),
                  icon: const Icon(Icons.auto_stories_outlined),
                ),
                IconButton(
                  tooltip: 'Exit exhibit',
                  onPressed: () {
                    ref.read(museumControllerProvider.notifier).returnToIdle();
                    context.go('/');
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              key: const ValueKey('exhibit-pages'),
              controller: _controller,
              itemCount: artifact.chapters.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                final chapter = artifact.chapters[index];
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: Column(
                        children: <Widget>[
                          if (index == 0) ...<Widget>[
                            Hero(
                              tag: 'artifact-${artifact.uid}',
                              child: ArtifactStage(
                                artifact: artifact,
                                compact: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            chapter.kicker.toUpperCase(),
                            style: textTheme.labelSmall,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            chapter.title,
                            textAlign: TextAlign.center,
                            style: textTheme.displayMedium,
                          ),
                          const SizedBox(height: 22),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Text(
                              chapter.body,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: 28),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: EverAfterColors.agedPaper.withValues(
                                alpha: 0.72,
                              ),
                              border: Border.all(
                                color: EverAfterColors.ink.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                chapter.detail,
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall,
                              ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                MuseumButton(
                  label: 'Previous',
                  icon: Icons.arrow_back,
                  onPressed: _page == 0
                      ? null
                      : () => _controller.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_page + 1} / ${artifact.chapters.length}',
                  style: textTheme.labelSmall,
                ),
                const SizedBox(width: 12),
                MuseumButton(
                  key: const ValueKey('next-chapter'),
                  label: _page == artifact.chapters.length - 1
                      ? 'Exit'
                      : 'Next',
                  icon: _page == artifact.chapters.length - 1
                      ? Icons.keyboard_return
                      : Icons.arrow_forward,
                  isPrimary: _page == artifact.chapters.length - 1,
                  onPressed: () {
                    if (_page == artifact.chapters.length - 1) {
                      ref
                          .read(museumControllerProvider.notifier)
                          .returnToIdle();
                      context.go('/');
                      return;
                    }
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
