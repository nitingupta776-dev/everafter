import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/memory_image.dart';
import 'package:everafter/widgets/museum_widgets.dart';
import 'package:everafter/widgets/trip_gallery.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TasteMemory {
  const TasteMemory({
    required this.place,
    required this.city,
    required this.dish,
    required this.note,
    required this.detail,
    required this.assetPath,
    required this.accessionNumber,
  });

  final String place;
  final String city;
  final String dish;
  final String note;
  final String detail;
  final String assetPath;
  final String accessionNumber;
}

const List<TasteMemory> tasteOfJapanMemories = <TasteMemory>[
  TasteMemory(
    place: 'Conveyor-belt Sushi',
    city: 'Tokyo',
    dish: 'Nigiri & spicy noodles',
    note:
        'Colourful plates of nigiri beside a steaming bowl.\nOur Tokyo table, exactly as we remember it.',
    detail:
        'Tuna, salmon, ginger, and a hot bowl of spicy noodles gathered around the conveyor-belt counter.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-001',
  ),
  TasteMemory(
    place: 'Soba Counter',
    city: 'Tokyo',
    dish: 'Tempura soba set',
    note:
        'Crisp tempura, cool soba, and a giant kakiage.\nA whole lunch arranged on one tray.',
    detail:
        'A generous soba set with dipping sauce, shredded vegetables, tempura, and a golden vegetable fritter.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-002',
  ),
  TasteMemory(
    place: 'Street Snack Stand',
    city: 'Tokyo',
    dish: 'Spiral potato',
    note:
        'A paper cup, a long skewer, and a tower of crisp potato.\nThe perfect walking snack.',
    detail:
        'Thin potato spirals fried until golden and dusted with seasoning, photographed just before the first bite.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-003',
  ),
  TasteMemory(
    place: 'Kyoto Street Stall',
    city: 'Kyoto',
    dish: 'Taiyaki',
    note:
        'Still warm and wrapped in paper.\nA fish-shaped sweet carried through Kyoto.',
    detail:
        'A freshly baked taiyaki, held in one hand while the street blurred softly behind it.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-004',
  ),
  TasteMemory(
    place: 'Matcha Stop',
    city: 'Kyoto',
    dish: 'Matcha soft serve',
    note:
        'Deep green soft serve with a crisp cone.\nA cool pause between Kyoto streets.',
    detail:
        'A tall swirl of matcha ice cream photographed against the warm wood of the shopfront.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-005',
  ),
  TasteMemory(
    place: 'Matcha Republic',
    city: 'Uji',
    dish: 'Layered matcha drink',
    note:
        'Cream, milk, and matcha stacked in soft layers.\nAlmost too pretty to stir.',
    detail:
        'A chilled matcha drink from Uji, with a vivid green base fading upward through milk and cream.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-006',
  ),
  TasteMemory(
    place: 'Kyoto Patisserie',
    city: 'Kyoto',
    dish: 'Strawberry shortcake',
    note:
        'Soft sponge, fresh cream, and bright strawberries.\nA small, immaculate slice.',
    detail:
        'The classic strawberry cake arrived as a neat wedge, topped with cream and one glossy berry.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-007',
  ),
  TasteMemory(
    place: 'Kyoto Patisserie',
    city: 'Kyoto',
    dish: 'Blueberry tart',
    note:
        'A tiny tart crowded with blueberries.\nGlossy fruit over a crisp pastry shell.',
    detail:
        'A berry-covered tart with custard beneath, photographed on the café table before we shared it.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-008',
  ),
  TasteMemory(
    place: 'Pancake Café',
    city: 'Kyoto',
    dish: 'Strawberry soufflé pancakes',
    note:
        'Pillowy pancakes under strawberries and cream.\nDessert with impossible height.',
    detail:
        'Two airy pancakes topped with fresh strawberries, whipped cream, sauce, and a dusting of sugar.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-009',
  ),
  TasteMemory(
    place: 'Dinner Table',
    city: 'Kyoto',
    dish: 'Kimchi pancake',
    note:
        'Crisp edges and a soft, savoury centre.\nOne evening, one shared plate.',
    detail:
        'A hot kimchi pancake cut into wedges and photographed at the table before everyone reached in.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-010',
  ),
  TasteMemory(
    place: 'Hanami Snack Stall',
    city: 'Kyoto',
    dish: 'Hanami dango',
    note:
        'Pink, white, and green on one skewer.\nA springtime sweet made for wandering.',
    detail:
        'Three soft rice dumplings in the colours of blossom season, held up against the Kyoto street.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-011',
  ),
  TasteMemory(
    place: 'Udon Counter',
    city: 'Osaka',
    dish: 'Udon',
    note:
        'Thick noodles, a bright egg yolk, and scallions.\nSimple, glossy, satisfying.',
    detail:
        'A bowl of springy udon dressed with egg, greens, sesame, and crisp tempura crumbs.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-012',
  ),
  TasteMemory(
    place: 'Osaka Sweet Shop',
    city: 'Osaka',
    dish: 'Strawberry daifuku',
    note:
        'A whole strawberry tucked into soft mochi.\nSweet, chewy, and gone too quickly.',
    detail:
        'The daifuku was split open to reveal bright fruit, red bean filling, and a delicate mochi shell.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-013',
  ),
  TasteMemory(
    place: 'Nara Café',
    city: 'Nara',
    dish: 'Berry soda & macarons',
    note:
        'A sparkling berry drink with two tiny companions.\nThe most playful café table of the trip.',
    detail:
        'A ruby soda crowned with berries, served beside two character-shaped macarons on a wooden tray.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-014',
  ),
  TasteMemory(
    place: 'Curry House',
    city: 'Nara',
    dish: 'Vegetable curry',
    note:
        'Rice, roasted vegetables, and two curries.\nA colourful plate after a long walk.',
    detail:
        'A generous curry plate with grains, greens, roasted vegetables, pickles, and contrasting sauces.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-015',
  ),
  TasteMemory(
    place: 'Nara Bakery',
    city: 'Nara',
    dish: 'Strawberry cream buns',
    note:
        'Golden buns filled with cream and berries.\nA bakery-window choice with no regrets.',
    detail:
        'Two soft pastries filled with whipped cream and fresh strawberries, dusted lightly with sugar.',
    assetPath: publicMemoryPlaceholderAsset,
    accessionNumber: 'EA-JP-016',
  ),
];

class TripTasteMenuScreen extends StatefulWidget {
  const TripTasteMenuScreen({required this.trip, super.key});

  final TripGalleryItem trip;

  @override
  State<TripTasteMenuScreen> createState() => _TripTasteMenuScreenState();
}

class _TripTasteMenuScreenState extends State<TripTasteMenuScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _ledgerController = ScrollController();
  late final AnimationController _contentController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 280),
  );
  int _selectedIndex = 0;
  bool _closing = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 110));
      if (mounted && !_closing) {
        await _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _ledgerController.dispose();
    super.dispose();
  }

  Future<void> _closeToGallery() async {
    if (_closing) return;
    _closing = true;
    await _contentController.reverse();
    if (!mounted) return;

    if (!context.canPop()) {
      context.go('/');
      return;
    }

    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.canPop()) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = tasteOfJapanMemories[_selectedIndex];

    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _closeToGallery();
        }
      },
      child: PaperScaffold(
        includeDust: true,
        backgroundAsset: 'assets/textures/warm_linen_canvas_visible.jpg',
        child: FadeTransition(
          key: const ValueKey('taste-menu-content-reveal'),
          opacity: CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 22, 36, 28),
            child: Column(
              children: <Widget>[
                _TasteRevealStage(
                  key: const ValueKey('taste-reveal-header'),
                  animation: _contentController,
                  start: 0,
                  end: 0.36,
                  child: _TasteHeader(
                    trip: widget.trip,
                    onBack: _closeToGallery,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: widget.trip.slug == 'japan'
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              child: _TasteRevealStage(
                                key: const ValueKey('taste-reveal-memory'),
                                animation: _contentController,
                                start: 0.16,
                                end: 0.7,
                                child: _LayeredPaperCard(
                                  child: _SelectedTasteMemory(
                                    key: ValueKey(
                                      'taste-detail-${selected.accessionNumber}',
                                    ),
                                    memory: selected,
                                    index: _selectedIndex,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: _TasteRevealStage(
                                key: const ValueKey('taste-reveal-ledger'),
                                animation: _contentController,
                                start: 0.38,
                                end: 1,
                                child: _LayeredPaperCard(
                                  child: _TasteLedger(
                                    controller: _ledgerController,
                                    selectedIndex: _selectedIndex,
                                    onSelected: (index) =>
                                        setState(() => _selectedIndex = index),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _TasteRevealStage(
                          key: const ValueKey('taste-reveal-empty-collection'),
                          animation: _contentController,
                          start: 0.16,
                          end: 0.82,
                          child: _UncuratedTasteCollection(trip: widget.trip),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TasteRevealStage extends StatelessWidget {
  const _TasteRevealStage({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = Interval(
          start,
          end,
          curve: Curves.easeOutCubic,
        ).transform(animation.value);
        return IgnorePointer(
          ignoring: progress < 0.98,
          child: Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - progress)),
              child: Transform.scale(
                alignment: Alignment.center,
                scale: 0.992 + (0.008 * progress),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TasteHeader extends StatelessWidget {
  const _TasteHeader({required this.trip, required this.onBack});

  final TripGalleryItem trip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 68,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 220,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('taste-back-to-gallery'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('BACK TO GALLERY'),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 42,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'TASTES OF ${trip.name.toUpperCase()}',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium?.copyWith(
                        fontFamily: 'Georgia',
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 3.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 12,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'A LEDGER OF CAFÉS, MARKETS, AND MEALS TO REMEMBER',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: EverAfterColors.warmBrown,
                        fontSize: 8.5,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 220),
        ],
      ),
    );
  }
}

class _UncuratedTasteCollection extends StatelessWidget {
  const _UncuratedTasteCollection({required this.trip});

  final TripGalleryItem trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SizedBox(
        key: ValueKey('taste-empty-${trip.slug}'),
        width: 620,
        height: 480,
        child: _LayeredPaperCard(
          arched: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(38, 42, 38, 34),
            child: Column(
              children: <Widget>[
                Text(
                  'EVERAFTER · MENU ${trip.number.toString().padLeft(2, '0')}',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(180),
                      bottom: Radius.circular(5),
                    ),
                    child: memoryImage(
                      trip.assetPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${trip.name.toUpperCase()}\nCOLLECTION',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    color: EverAfterColors.ink,
                    fontSize: 31,
                    height: 1,
                    letterSpacing: 2.8,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'MENU COLLECTION IN PROGRESS',
                  key: const ValueKey('taste-menu-in-progress'),
                  style: textTheme.labelLarge?.copyWith(
                    color: EverAfterColors.warmBrown,
                    fontSize: 9,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CAFÉS · MARKETS · MEALS',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedTasteMemory extends StatelessWidget {
  const _SelectedTasteMemory({
    required this.memory,
    required this.index,
    super.key,
  });

  final TasteMemory memory;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Padding(
        key: ValueKey(memory.accessionNumber),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'MEMORY ${(index + 1).toString().padLeft(2, '0')}',
                  style: textTheme.labelSmall?.copyWith(fontSize: 8),
                ),
                const Spacer(),
                Text(
                  memory.accessionNumber,
                  style: textTheme.labelSmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 5,
              child: Transform.scale(
                scale: 1.18,
                child: _EmbossedFoodImageFrame(memory: memory),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              memory.place.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  memory.dish.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(fontSize: 9),
                ),
                const SizedBox(width: 9),
                const Icon(Icons.diamond_outlined, size: 8),
                const SizedBox(width: 9),
                Text(
                  memory.city.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              memory.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ErraticCursive',
                color: EverAfterColors.ink,
                fontSize: 21,
                height: 1.04,
                letterSpacing: 0.1,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              memory.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: EverAfterColors.ink.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: EverAfterColors.ink.withValues(alpha: 0.22),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'EVERAFTER COLLECTION',
                  style: textTheme.labelSmall?.copyWith(fontSize: 7.5),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.diamond_outlined, size: 8),
                const SizedBox(width: 12),
                Text(
                  '${index + 1} OF ${tasteOfJapanMemories.length}',
                  style: textTheme.labelSmall?.copyWith(fontSize: 7.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmbossedFoodImageFrame extends StatelessWidget {
  const _EmbossedFoodImageFrame({required this.memory});

  final TasteMemory memory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = constraints.maxWidth * 0.13;
        final verticalInset = constraints.maxHeight * 0.18;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: verticalInset,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  memory.assetPath,
                  key: ValueKey('taste-image-${memory.accessionNumber}'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            IgnorePointer(
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.17008,
                  0.57216,
                  0.05776,
                  0,
                  60,
                  0.17008,
                  0.57216,
                  0.05776,
                  0,
                  52,
                  0.17008,
                  0.57216,
                  0.05776,
                  0,
                  33,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Image.asset(
                  'assets/images/taste/embossed_food_frame.png',
                  key: const ValueKey('taste-embossed-food-frame'),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LayeredPaperCard extends StatelessWidget {
  const _LayeredPaperCard({required this.child, this.arched = false});

  final Widget child;
  final bool arched;

  BorderRadius get _radius => BorderRadius.vertical(
    top: Radius.circular(arched ? 190 : 7),
    bottom: const Radius.circular(7),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(10, 9),
            child: Transform.rotate(
              angle: 0.006,
              child: DecoratedBox(
                key: const ValueKey('taste-background-card-back'),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3D2AF),
                  border: Border.all(color: const Color(0x5E5C4933)),
                  borderRadius: _radius,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x2B3A2C1E),
                      blurRadius: 14,
                      offset: Offset(4, 7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(5, 4),
            child: Transform.rotate(
              angle: -0.004,
              child: DecoratedBox(
                key: const ValueKey('taste-background-card-middle'),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE0C5),
                  border: Border.all(color: const Color(0x665C4933)),
                  borderRadius: _radius,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: _radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECD9),
                border: Border.all(
                  color: EverAfterColors.ink.withValues(alpha: 0.46),
                  width: 1.1,
                ),
                borderRadius: _radius,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F3A2C1E),
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Opacity(
                    opacity: 0.18,
                    child: Image.asset(
                      'assets/textures/warm_linen_canvas_fine.jpg',
                      fit: BoxFit.cover,
                      color: const Color(0xFFE3D2AF),
                      colorBlendMode: BlendMode.multiply,
                      excludeFromSemantics: true,
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Retained as an unused archive of the later lace-menu experiment.
// ignore: unused_element
class _TasteMemoryStrip extends StatelessWidget {
  const _TasteMemoryStrip({
    required this.controller,
    required this.selectedIndex,
    required this.onSelected,
  });

  final ScrollController controller;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0x00FFFFFF)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        child: Column(
          children: <Widget>[
            const SizedBox(
              key: ValueKey('taste-select-a-memory-card'),
              height: 48,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Divider(
                            color: Color(0x889B7642),
                            indent: 18,
                            endIndent: 8,
                          ),
                        ),
                        Icon(
                          Icons.diamond_outlined,
                          size: 10,
                          color: Color(0xFF9B7642),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'THE MENU',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            color: Color(0xFF2A2520),
                            fontSize: 21,
                            height: 1,
                            letterSpacing: 1.8,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.diamond_outlined,
                          size: 10,
                          color: Color(0xFF9B7642),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color(0x889B7642),
                            indent: 8,
                            endIndent: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      'SELECT A MEMORY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: Color(0xFF8A2D25),
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Scrollbar(
                controller: controller,
                thumbVisibility: true,
                interactive: true,
                child: ListView.separated(
                  key: const ValueKey('taste-ledger-list'),
                  controller: controller,
                  padding: const EdgeInsets.only(right: 7),
                  itemCount: tasteOfJapanMemories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 3),
                  itemBuilder: (context, index) {
                    final memory = tasteOfJapanMemories[index];
                    final selected = index == selectedIndex;
                    return Semantics(
                      selected: selected,
                      button: true,
                      label: 'Open ${memory.place}, ${memory.dish}',
                      child: Material(
                        color: selected
                            ? const Color(0x44D5B77B)
                            : const Color(0x00FFFFFF),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF9B7642)
                                : const Color(0x554A4035),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('taste-ledger-item-$index'),
                          onTap: () => onSelected(index),
                          child: SizedBox(
                            height: 58,
                            child: Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 92,
                                  height: double.infinity,
                                  child: Image.asset(
                                    memory.assetPath,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 2,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          (index + 1).toString().padLeft(
                                            2,
                                            '0',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Georgia',
                                            color: const Color(0xFF8A2D25),
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          memory.place.toUpperCase(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Georgia',
                                            color: const Color(0xFF2A2520),
                                            fontSize: 16.5,
                                            height: 0.96,
                                            letterSpacing: 0.5,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          memory.city.toUpperCase(),
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontFamily: 'Georgia',
                                            color: const Color(0xFF755B3D),
                                            fontSize: 6.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Container(
                                    width: 16,
                                    color: const Color(0xFF681E1A),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.diamond_outlined,
                                      size: 10,
                                      color: Color(0xFFD2A75D),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

// Kept for compatibility with older menu experiments that may be revived.
// ignore: unused_element
class _TasteLedger extends StatelessWidget {
  const _TasteLedger({
    required this.controller,
    required this.selectedIndex,
    required this.onSelected,
  });

  final ScrollController controller;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text(
                'THE LEDGER',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: EverAfterColors.ink,
                  fontSize: 23,
                  height: 1,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Text(
                '${tasteOfJapanMemories.length} MEMORIES',
                style: textTheme.labelSmall?.copyWith(fontSize: 7.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: EverAfterColors.ink.withValues(alpha: 0.36),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Scrollbar(
              controller: controller,
              thumbVisibility: true,
              interactive: true,
              child: ListView.separated(
                key: const ValueKey('taste-ledger-list'),
                controller: controller,
                padding: const EdgeInsets.only(right: 11),
                itemCount: tasteOfJapanMemories.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: EverAfterColors.ink.withValues(alpha: 0.19),
                ),
                itemBuilder: (context, index) => _TasteLedgerRow(
                  memory: tasteOfJapanMemories[index],
                  index: index,
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _SelectMemoryCard(),
        ],
      ),
    );
  }
}

class _SelectMemoryCard extends StatelessWidget {
  const _SelectMemoryCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: const ValueKey('taste-select-a-memory-card'),
        width: 300,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F1E2),
          border: Border.all(
            color: EverAfterColors.ink.withValues(alpha: 0.55),
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x263A2C1E),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.diamond_outlined, size: 10),
            SizedBox(width: 16),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'SELECT A MEMORY',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: EverAfterColors.ink,
                    fontSize: 18,
                    letterSpacing: 2.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Icon(Icons.diamond_outlined, size: 10),
          ],
        ),
      ),
    );
  }
}

class _TasteLedgerRow extends StatelessWidget {
  const _TasteLedgerRow({
    required this.memory,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final TasteMemory memory;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: 'Open ${memory.place}, ${memory.dish}',
      child: Material(
        color: selected
            ? EverAfterColors.agedPaper.withValues(alpha: 0.62)
            : Colors.transparent,
        shape: selected
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: EverAfterColors.ink.withValues(alpha: 0.36),
                ),
                borderRadius: BorderRadius.circular(5),
              )
            : null,
        child: InkWell(
          key: ValueKey('taste-ledger-item-$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 82,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 28,
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: selected
                            ? EverAfterColors.ink
                            : EverAfterColors.warmBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                      bottom: Radius.circular(3),
                    ),
                    child: SizedBox(
                      width: 92,
                      height: 64,
                      child: Image.asset(
                        memory.assetPath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          memory.place.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            fontFamily: 'Georgia',
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${memory.dish.toUpperCase()}  ·  ${memory.city.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(fontSize: 7),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          memory.note.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'ErraticCursive',
                            color: EverAfterColors.ink,
                            fontSize: 13,
                            height: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 34,
                    child: Text(
                      memory.accessionNumber.replaceFirst('EA-JP-', 'NO.\n'),
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 6.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
