import 'dart:async';

import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/trip_catalog_store.dart';
import 'package:everafter/models/travel_artifact.dart';
import 'package:everafter/services/memory_folder_browser.dart';
import 'package:everafter/services/memory_sync_runner.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:everafter/widgets/memory_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Admin screen for managing which trips are visited (shown in the
/// gallery/globe), registering each trip's real photos, and editing the
/// fridge-magnet exhibit copy. Mirrors [GalleryAdminScreen]'s "Save
/// global" (web, writes the bundled JSON) vs "Save this device"
/// (SharedPreferences override) split.
class TripAdminScreen extends StatefulWidget {
  const TripAdminScreen({super.key});

  @override
  State<TripAdminScreen> createState() => _TripAdminScreenState();
}

class _TripAdminScreenState extends State<TripAdminScreen> {
  final TripCatalogStore _store = TripCatalogStore.instance;
  final MemoryFolderBrowser _folderBrowser = createMemoryFolderBrowser();
  final MemorySyncRunner _syncRunner = createMemorySyncRunner();
  late final TextEditingController _externalRootController =
      TextEditingController(text: _store.externalMemoriesRoot ?? '');
  String? _selectedSlug;
  final List<MemoryFolderFile> _pendingFiles = <MemoryFolderFile>[];
  bool _isChoosingPhotos = false;
  bool _isSyncing = false;

  @override
  void dispose() {
    _externalRootController.dispose();
    super.dispose();
  }

  TripGalleryItem? get _selectedTrip {
    final slug = _selectedSlug;
    if (slug == null) return null;
    for (final trip in _store.allTrips) {
      if (trip.slug == slug) return trip;
    }
    return null;
  }

  Future<void> _syncPhotos() async {
    if (!_syncRunner.isSupported) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Run sync from terminal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo sync is not supported in the web/browser environment. '
                    'Run this command from your project root:',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const SelectableText(
                      'python3 tool/sync_memory_collections.py',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFFE7C7B3),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Then hot-restart the app to pick up the changes.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E8880)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it'),
                ),
              ],
            ),
      );
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final result = await _syncRunner.run();
      await _store.load();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? result.output.isNotEmpty
                    ? result.output
                    : 'Sync complete.'
                : 'Sync failed: ${result.output}',
          ),
          backgroundColor: result.success
              ? const Color(0xFF3A5C3A)
              : const Color(0xFF5C2A2A),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: const Color(0xFFE7C7B3),
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _adminTheme(Theme.of(context)),
      child: Scaffold(
        key: const ValueKey('trip-admin-screen'),
        backgroundColor: const Color(0xFF17100E),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _store,
            builder: (context, _) {
              return Column(
                children: <Widget>[
                  _buildHeader(),
                  if (_store.supportsExternalMemories) _buildExternalRootBar(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(width: 340, child: _buildTripList()),
                        const VerticalDivider(
                          width: 1,
                          color: Color(0xFF4C3931),
                        ),
                        Expanded(child: _buildDetail()),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF231815),
        border: Border(bottom: BorderSide(color: Color(0xFF513B33))),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Back to EverAfter',
            onPressed: () => context.go('/'),
            color: EverAfterColors.agedPaper,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'TRIPS & MEMORIES',
                style: TextStyle(
                  color: EverAfterColors.agedPaper,
                  fontFamily: 'Georgia',
                  fontSize: 19,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Hide unvisited destinations, register photos, edit magnets',
                style: TextStyle(color: Color(0xFFBCA99C), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Container(
            key: const ValueKey('trip-admin-scope'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF352520),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF654A40)),
            ),
            child: Text(
              _store.editsGlobalCatalog ? 'GLOBAL CATALOG' : 'THIS DEVICE ONLY',
              style: const TextStyle(
                color: Color(0xFFD7B27C),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            key: const ValueKey('trip-admin-sync-photos'),
            onPressed: _isSyncing ? null : _syncPhotos,
            icon: _isSyncing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFE7C7B3),
                    ),
                  )
                : const Icon(Icons.sync),
            label: Text(_isSyncing ? 'Syncing…' : 'Sync photos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE7C7B3),
              side: const BorderSide(color: Color(0xFF785C50)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            key: const ValueKey('trip-admin-reset'),
            onPressed: () async {
              await _store.resetToGlobal();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE7C7B3),
              side: const BorderSide(color: Color(0xFF785C50)),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            key: const ValueKey('trip-admin-save'),
            onPressed: _store.hasUnsavedChanges
                ? () async {
                    await _store.save();
                    if (mounted) setState(() {});
                  }
                : null,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              _store.hasUnsavedChanges
                  ? (_store.editsGlobalCatalog
                        ? 'Save global'
                        : 'Save this device')
                  : 'Saved',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB58A54),
              foregroundColor: const Color(0xFF24160E),
              disabledBackgroundColor: const Color(0xFF4A403A),
              disabledForegroundColor: const Color(0xFFA99D95),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalRootBar() {
    final configuredRoot = _store.externalMemoriesRoot;
    return Container(
      key: const ValueKey('trip-admin-external-root-bar'),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1D1512),
        border: Border(bottom: BorderSide(color: Color(0xFF3A2B24))),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.sd_card_outlined,
            size: 16,
            color: Color(0xFFD7B27C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('trip-admin-external-root-field'),
              controller: _externalRootController,
              style: const TextStyle(
                color: EverAfterColors.agedPaper,
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText:
                    'External photos root (e.g. /media/pi/EVERAFTER) — '
                    'leave blank to only use bundled/registered photos',
                hintStyle: TextStyle(color: Color(0xFF6E5C52), fontSize: 12),
              ),
              onSubmitted: (value) => _store.setExternalMemoriesRoot(value),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            key: const ValueKey('trip-admin-set-external-root'),
            onPressed: () =>
                _store.setExternalMemoriesRoot(_externalRootController.text),
            child: const Text('Set root'),
          ),
          TextButton.icon(
            key: const ValueKey('trip-admin-rescan-external-root'),
            onPressed: configuredRoot == null
                ? null
                : () => _store.rescanExternalMemories(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Rescan'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList() {
    final trips = List<TripGalleryItem>.of(_store.allTrips)
      ..sort((a, b) => a.name.compareTo(b.name));
    return ListView.separated(
      key: const ValueKey('trip-admin-list'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: trips.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFF3A2B24)),
      itemBuilder: (context, index) {
        final trip = trips[index];
        final photoCount = _store
            .memoryLocationsFor(trip.slug)
            .fold<int>(0, (sum, location) => sum + location.assetPaths.length);
        final selected = trip.slug == _selectedSlug;
        return ListTile(
          key: ValueKey('trip-admin-row-${trip.slug}'),
          selected: selected,
          selectedTileColor: const Color(0xFF352520),
          title: Text(
            trip.name,
            style: const TextStyle(color: EverAfterColors.agedPaper),
          ),
          subtitle: Text(
            '$photoCount photo${photoCount == 1 ? '' : 's'}'
            '${trip.memoriesFolder == null ? '' : '  ·  assets/memories/${trip.memoriesFolder}/'}',
            style: const TextStyle(color: Color(0xFF9C877A), fontSize: 11),
          ),
          trailing: Switch(
            key: ValueKey('trip-admin-visited-${trip.slug}'),
            value: trip.visited,
            activeThumbColor: const Color(0xFFB58A54),
            onChanged: (visited) => _store.setVisited(trip.slug, visited),
          ),
          onTap: () => setState(() {
            _selectedSlug = trip.slug;
            _pendingFiles.clear();
          }),
        );
      },
    );
  }

  Widget _buildDetail() {
    final trip = _selectedTrip;
    if (trip == null) {
      return const Center(
        child: Text(
          'Select a trip to manage its memories',
          style: TextStyle(color: Color(0xFF9C877A)),
        ),
      );
    }
    final locations = _store.memoryLocationsFor(trip.slug);
    return SingleChildScrollView(
      key: ValueKey('trip-admin-detail-${trip.slug}'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            trip.name,
            style: const TextStyle(
              color: EverAfterColors.agedPaper,
              fontFamily: 'Georgia',
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Slug: ${trip.slug}${trip.country == null ? '' : '  ·  ${trip.country}'}',
            style: const TextStyle(color: Color(0xFF9C877A), fontSize: 12),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Visited'),
          SwitchListTile(
            key: ValueKey('trip-admin-detail-visited-${trip.slug}'),
            contentPadding: EdgeInsets.zero,
            value: trip.visited,
            activeThumbColor: const Color(0xFFB58A54),
            title: const Text(
              'Show this trip in the gallery and globe',
              style: TextStyle(color: EverAfterColors.agedPaper, fontSize: 13),
            ),
            onChanged: (visited) => _store.setVisited(trip.slug, visited),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Cover photo'),
          const SizedBox(height: 8),
          _buildCoverPhotoSection(trip, locations),
          const SizedBox(height: 20),
          _sectionLabel('Photos & videos'),
          const SizedBox(height: 8),
          if (trip.memoriesFolder == null)
            const Text(
              'This demo trip has no assets/memories/ folder assigned, so '
              'photos can\'t be registered here yet.',
              style: TextStyle(color: Color(0xFF9C877A), fontSize: 12),
            )
          else ...<Widget>[
            Row(
              children: <Widget>[
                FilledButton.icon(
                  key: const ValueKey('trip-admin-choose-photos'),
                  onPressed: _folderBrowser.isSupported && !_isChoosingPhotos
                      ? () => _choosePhotos(trip)
                      : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _isChoosingPhotos ? 'Choosing…' : 'Choose photos',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB58A54),
                    foregroundColor: const Color(0xFF24160E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _folderBrowser.isSupported
                        ? 'Opens your file picker. Navigate to '
                              'assets/memories/${trip.memoriesFolder}/ and '
                              'select the photos you want to register.'
                        : 'Photo picking only works in the web admin build '
                              '(flutter run -d web-server).',
                    style: const TextStyle(
                      color: Color(0xFF9C877A),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (_store.externalMemoriesRoot != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Also checking '
                '${_store.externalMemoriesRoot}/${trip.memoriesFolder}/ '
                'live (an external photos root is configured above) — '
                'anything found there is used instead of what\'s '
                'registered below. Use Rescan after changing files on it.',
                style: const TextStyle(color: Color(0xFF9C877A), fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            if (_pendingFiles.isNotEmpty) ...<Widget>[
              Text(
                '${_pendingFiles.length} selected — not yet added',
                style: const TextStyle(color: Color(0xFFD7B27C), fontSize: 12),
              ),
              const SizedBox(height: 8),
              _photoGrid(
                _pendingFiles
                    .map(
                      (file) => _PhotoTile(
                        label: file.fileName,
                        imageProvider: NetworkImage(file.previewUrl),
                        onRemove: () =>
                            setState(() => _pendingFiles.remove(file)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('trip-admin-add-pending-photos'),
                onPressed: () => _addPendingPhotos(trip),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF76826A),
                  foregroundColor: const Color(0xFF17100E),
                ),
                child: Text('Add ${_pendingFiles.length} to collection'),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Registered (${locations.fold<int>(0, (sum, l) => sum + l.assetPaths.length)})',
              style: const TextStyle(color: Color(0xFFD7B27C), fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (locations.isEmpty)
              const Text(
                'No photos registered yet.',
                style: TextStyle(color: Color(0xFF9C877A), fontSize: 12),
              )
            else
              for (final location in locations) ...<Widget>[
                Text(
                  location.label,
                  style: const TextStyle(
                    color: EverAfterColors.agedPaper,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                _photoGrid(<Widget>[
                  for (final assetPath in location.assetPaths)
                    if (location.videoPosterPaths.containsKey(assetPath))
                      _VideoPreviewTile(
                        label: assetPath.split('/').last,
                        assetPath: assetPath,
                        onRemove: () =>
                            _removeRegisteredPhoto(trip, location, assetPath),
                      )
                    else
                    _PhotoTile(
                      label: assetPath.split('/').last,
                      imageProvider: memoryImageProvider(assetPath),
                      onRemove: () =>
                          _removeRegisteredPhoto(trip, location, assetPath),
                    ),
                ]),
                const SizedBox(height: 16),
              ],
          ],
          const SizedBox(height: 28),
          _sectionLabel('Fridge magnet'),
          const SizedBox(height: 8),
          _ArtifactEditor(trip: trip, store: _store),
        ],
      ),
    );
  }

  Widget _buildCoverPhotoSection(
    TripGalleryItem trip,
    List<JapanMemoryLocation> locations,
  ) {
    final imageAssets = <String>[
      for (final location in locations)
        for (final path in location.assetPaths)
          if (!location.videoPosterPaths.containsKey(path)) path,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _CoverThumbnail(assetPath: trip.assetPath, selected: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    trip.assetPath.split('/').last,
                    style: const TextStyle(
                      color: EverAfterColors.agedPaper,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap any registered photo below to use it as the gallery card cover.',
                    style: TextStyle(color: Color(0xFF9C877A), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (imageAssets.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final path in imageAssets)
                GestureDetector(
                  onTap: () => _store.updateTrip(trip.copyWith(assetPath: path)),
                  child: _CoverThumbnail(
                    assetPath: path,
                    selected: trip.assetPath == path,
                  ),
                ),
            ],
          ),
        ] else if (locations.isEmpty)
          const Text(
            'Register photos first, then tap one to set as cover.',
            style: TextStyle(color: Color(0xFF9C877A), fontSize: 12),
          ),
      ],
    );
  }

  Widget _sectionLabel(String label) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: Color(0xFFD7B27C),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ),
  );

  Widget _photoGrid(List<Widget> tiles) {
    return Wrap(spacing: 10, runSpacing: 10, children: tiles);
  }

  Future<void> _choosePhotos(TripGalleryItem trip) async {
    setState(() => _isChoosingPhotos = true);
    try {
      final files = await _folderBrowser.choosePhotos();
      if (!mounted) return;
      setState(() {
        _pendingFiles
          ..clear()
          ..addAll(files);
      });
    } finally {
      if (mounted) setState(() => _isChoosingPhotos = false);
    }
  }

  void _addPendingPhotos(TripGalleryItem trip) {
    final folder = trip.memoriesFolder;
    if (folder == null || _pendingFiles.isEmpty) return;

    final existingLocations = _store.memoryLocationsFor(trip.slug);
    final target = existingLocations.isNotEmpty
        ? existingLocations.first
        : JapanMemoryLocation(
            slug: '${trip.slug}-trip',
            label: trip.name,
            assetPaths: const <String>[],
          );

    final newAssetPaths = <String>[...target.assetPaths];
    final newVideoPosters = <String, String>{...target.videoPosterPaths};
    for (final file in _pendingFiles) {
      final assetPath = 'assets/memories/$folder/${file.fileName}';
      if (newAssetPaths.contains(assetPath)) continue;
      newAssetPaths.add(assetPath);
      if (file.isVideo) {
        // No poster picked yet; fall back to a static placeholder so the
        // grid still renders something instead of trying to decode video
        // bytes as an image. Swap in a real poster later by editing
        // memory_collections.json or re-registering with a poster flow.
        newVideoPosters[assetPath] =
            'assets/images/experience/earth-globe-fallback.png';
      }
    }

    final updatedLocation = JapanMemoryLocation(
      slug: target.slug,
      label: target.label,
      assetPaths: newAssetPaths,
      videoPosterPaths: newVideoPosters,
    );
    final updatedLocations = existingLocations.isNotEmpty
        ? <JapanMemoryLocation>[updatedLocation, ...existingLocations.skip(1)]
        : <JapanMemoryLocation>[updatedLocation];

    _store.setMemoryLocations(trip.slug, updatedLocations);
    setState(() => _pendingFiles.clear());
  }

  void _removeRegisteredPhoto(
    TripGalleryItem trip,
    JapanMemoryLocation location,
    String assetPath,
  ) {
    final updatedLocation = JapanMemoryLocation(
      slug: location.slug,
      label: location.label,
      assetPaths: location.assetPaths
          .where((path) => path != assetPath)
          .toList(growable: false),
      videoPosterPaths: Map<String, String>.of(location.videoPosterPaths)
        ..remove(assetPath),
    );
    final locations = _store.memoryLocationsFor(trip.slug);
    final updatedLocations = <JapanMemoryLocation>[
      for (final current in locations)
        if (current.slug == location.slug) updatedLocation else current,
    ];
    _store.setMemoryLocations(trip.slug, updatedLocations);
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.label,
    required this.imageProvider,
    required this.onRemove,
  });

  final String label;
  final ImageProvider imageProvider;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF4C3931)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(
                        color: Color(0xFF352520),
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF9C877A),
                        ),
                      ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Color(0xCC000000),
                child: Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: const Color(0xB2000000),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPreviewTile extends StatefulWidget {
  const _VideoPreviewTile({
    required this.label,
    required this.assetPath,
    required this.onRemove,
  });

  final String label;
  final String assetPath;
  final VoidCallback onRemove;

  @override
  State<_VideoPreviewTile> createState() => _VideoPreviewTileState();
}

class _VideoPreviewTileState extends State<_VideoPreviewTile> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(muted: true),
    );
    _controller = VideoController(_player);
    final assetPath = widget.assetPath;
    unawaited(
      _player.open(
        Media(
          isBundledAssetPath(assetPath) ? 'asset:///$assetPath' : assetPath,
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF4C3931)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Video(
                  controller: _controller,
                  fit: BoxFit.cover,
                  fill: const Color(0xFF17100E),
                  controls: NoVideoControls,
                  wakelock: false,
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: InkWell(
              onTap: widget.onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Color(0xCC000000),
                child: Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: const Color(0xB2000000),
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverThumbnail extends StatelessWidget {
  const _CoverThumbnail({required this.assetPath, required this.selected});

  final String assetPath;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? const Color(0xFFB58A54) : const Color(0xFF4C3931),
          width: selected ? 2.5 : 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image(
          image: memoryImageProvider(assetPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(
            color: Color(0xFF352520),
            child: Icon(
              Icons.broken_image_outlined,
              color: Color(0xFF9C877A),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtifactEditor extends StatefulWidget {
  const _ArtifactEditor({required this.trip, required this.store});

  final TripGalleryItem trip;
  final TripCatalogStore store;

  @override
  State<_ArtifactEditor> createState() => _ArtifactEditorState();
}

class _ArtifactEditorState extends State<_ArtifactEditor> {
  late TravelArtifact _draft;
  bool _existed = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void didUpdateWidget(covariant _ArtifactEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.slug != widget.trip.slug) {
      _loadDraft();
    }
  }

  void _loadDraft() {
    final existing = widget.store.artifacts
        .where((artifact) => artifact.place == widget.trip.name)
        .toList();
    _existed = existing.isNotEmpty;
    _draft = existing.isNotEmpty
        ? existing.first
        : TravelArtifact(
            uid: 'EA-${widget.trip.slug.toUpperCase()}-001',
            title: '${widget.trip.name} Travel Token',
            place: widget.trip.name,
            country: widget.trip.country ?? widget.trip.name,
            dateLabel: 'Undated',
            coordinates:
                '${widget.trip.latitude} N, ${widget.trip.longitude} E',
            medium: 'NFC tag',
            collection: '${widget.trip.name} journeys',
            accessionNumber: 'EA-${widget.trip.slug.toUpperCase()}-001',
            coverLine:
                'A small token that opens the route through '
                '${widget.trip.name}.',
            modelAsset: 'models/fridge_magnet/fridge_magnet.glb',
            colors: const <Color>[
              EverAfterColors.burgundy,
              EverAfterColors.brass,
              EverAfterColors.olive,
            ],
            chapters: const <ExhibitChapter>[
              ExhibitChapter(
                kicker: 'Cover',
                title: 'The journey begins with a single tap.',
                body: '',
                detail: '',
              ),
              ExhibitChapter(
                kicker: 'Journey',
                title: 'A route held inside one trip.',
                body: '',
                detail: '',
              ),
              ExhibitChapter(
                kicker: 'End',
                title: 'The tag returns the journey to the room.',
                body: '',
                detail: '',
              ),
            ],
          );
  }

  void _save() {
    widget.store.upsertArtifact(_draft);
    setState(() => _existed = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _existed
              ? 'Editing the existing magnet for ${widget.trip.name}'
              : 'No magnet yet for ${widget.trip.name} — fill this in and save '
                    'to create one',
          style: const TextStyle(color: Color(0xFF9C877A), fontSize: 12),
        ),
        const SizedBox(height: 12),
        _textField('Title', _draft.title, (v) => _draft = _copyDraft(title: v)),
        _textField(
          'Cover line',
          _draft.coverLine,
          (v) => _draft = _copyDraft(coverLine: v),
        ),
        _textField('NFC UID', _draft.uid, (v) => _draft = _copyDraft(uid: v)),
        for (var i = 0; i < _draft.chapters.length; i++) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            _draft.chapters[i].kicker.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFD7B27C),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          _textField(
            'Chapter title',
            _draft.chapters[i].title,
            (v) => _draft = _copyChapter(i, title: v),
          ),
          _textField(
            'Chapter body',
            _draft.chapters[i].body,
            (v) => _draft = _copyChapter(i, body: v),
            maxLines: 3,
          ),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          key: ValueKey('trip-admin-save-artifact-${widget.trip.slug}'),
          onPressed: _save,
          icon: const Icon(Icons.badge_outlined),
          label: Text(_existed ? 'Update magnet' : 'Create magnet'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF76826A),
            foregroundColor: const Color(0xFF17100E),
          ),
        ),
      ],
    );
  }

  TravelArtifact _copyDraft({String? title, String? coverLine, String? uid}) {
    return TravelArtifact(
      uid: uid ?? _draft.uid,
      title: title ?? _draft.title,
      place: _draft.place,
      country: _draft.country,
      dateLabel: _draft.dateLabel,
      coordinates: _draft.coordinates,
      medium: _draft.medium,
      collection: _draft.collection,
      accessionNumber: _draft.accessionNumber,
      coverLine: coverLine ?? _draft.coverLine,
      modelAsset: _draft.modelAsset,
      colors: _draft.colors,
      chapters: _draft.chapters,
    );
  }

  TravelArtifact _copyChapter(int index, {String? title, String? body}) {
    final chapters = List<ExhibitChapter>.of(_draft.chapters);
    final current = chapters[index];
    chapters[index] = ExhibitChapter(
      kicker: current.kicker,
      title: title ?? current.title,
      body: body ?? current.body,
      detail: current.detail,
    );
    return TravelArtifact(
      uid: _draft.uid,
      title: _draft.title,
      place: _draft.place,
      country: _draft.country,
      dateLabel: _draft.dateLabel,
      coordinates: _draft.coordinates,
      medium: _draft.medium,
      collection: _draft.collection,
      accessionNumber: _draft.accessionNumber,
      coverLine: _draft.coverLine,
      modelAsset: _draft.modelAsset,
      colors: _draft.colors,
      chapters: chapters,
    );
  }

  Widget _textField(
    String label,
    String initialValue,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: ValueKey('trip-admin-field-${widget.trip.slug}-$label'),
        initialValue: initialValue,
        maxLines: maxLines,
        style: const TextStyle(color: EverAfterColors.agedPaper, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF9C877A), fontSize: 12),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4C3931)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFB58A54)),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

ThemeData _adminTheme(ThemeData base) {
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: EverAfterColors.agedPaper,
      displayColor: EverAfterColors.agedPaper,
    ),
    listTileTheme: const ListTileThemeData(iconColor: Color(0xFFD7B27C)),
  );
}
