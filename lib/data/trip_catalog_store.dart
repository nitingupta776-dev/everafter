import 'dart:convert';

import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/models/travel_artifact.dart';
import 'package:everafter/services/external_memory_scanner.dart';
import 'package:everafter/services/global_json_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
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
    this.visited = false,
    this.memoriesFolder,
    this.country,
  });

  final int number;
  final String name;
  final String assetPath;
  final String? startDateLabel;
  final String? endDateLabel;
  final int? totalDays;
  final double latitude;
  final double longitude;

  /// Whether this destination should appear in the visible trip gallery and
  /// globe. Trips stay in the catalog (routable by slug, e.g. for a magnet)
  /// even while hidden.
  final bool visited;

  /// The literal folder name under `assets/memories/` holding this trip's
  /// real photos, e.g. `bali`. May differ from [slug] (folder names on disk
  /// are not always URL-friendly). Null for demo entries with no real
  /// folder.
  final String? memoriesFolder;

  final String? country;

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

  TripGalleryItem copyWith({
    int? number,
    String? name,
    String? assetPath,
    String? startDateLabel,
    String? endDateLabel,
    int? totalDays,
    double? latitude,
    double? longitude,
    bool? visited,
    String? memoriesFolder,
    String? country,
  }) {
    return TripGalleryItem(
      number: number ?? this.number,
      name: name ?? this.name,
      assetPath: assetPath ?? this.assetPath,
      startDateLabel: startDateLabel ?? this.startDateLabel,
      endDateLabel: endDateLabel ?? this.endDateLabel,
      totalDays: totalDays ?? this.totalDays,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visited: visited ?? this.visited,
      memoriesFolder: memoriesFolder ?? this.memoriesFolder,
      country: country ?? this.country,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'number': number,
    'name': name,
    'assetPath': assetPath,
    'startDateLabel': startDateLabel,
    'endDateLabel': endDateLabel,
    'totalDays': totalDays,
    'latitude': latitude,
    'longitude': longitude,
    'visited': visited,
    'memoriesFolder': memoriesFolder,
    'country': country,
  };

  factory TripGalleryItem.fromJson(Map<String, dynamic> json) {
    return TripGalleryItem(
      number: (json['number'] as num).toInt(),
      name: json['name'] as String,
      assetPath: json['assetPath'] as String,
      startDateLabel: json['startDateLabel'] as String?,
      endDateLabel: json['endDateLabel'] as String?,
      totalDays: (json['totalDays'] as num?)?.toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      visited: json['visited'] as bool? ?? false,
      memoriesFolder: json['memoriesFolder'] as String?,
      country: json['country'] as String?,
    );
  }
}

/// Loads and edits the trip list, fridge-magnet artifacts, and per-trip
/// photo/video collections. Mirrors [GalleryLayoutStore]'s bundled-JSON +
/// device-override persistence, but keeps whole-document overrides instead
/// of per-field patches, since these catalogs are small.
class TripCatalogStore extends ChangeNotifier {
  TripCatalogStore._()
    : _tripsFile = createGlobalJsonFile('trips.json'),
      _artifactsFile = createGlobalJsonFile('artifacts.json'),
      _collectionsFile = createGlobalJsonFile('memory_collections.json'),
      _externalScanner = createExternalMemoryScanner();

  static final TripCatalogStore instance = TripCatalogStore._();

  static const String _bundledTripsPath = 'assets/data/trips.json';
  static const String _bundledArtifactsPath = 'assets/data/artifacts.json';
  static const String _bundledCollectionsPath =
      'assets/data/memory_collections.json';
  static const String _deviceOverridesKey =
      'everafter.trip-catalog.device-overrides.v1';
  static const String _externalMemoriesRootKey =
      'everafter.trip-catalog.external-memories-root.v1';

  final GlobalJsonFile _tripsFile;
  final GlobalJsonFile _artifactsFile;
  final GlobalJsonFile _collectionsFile;
  final ExternalMemoryScanner _externalScanner;

  List<TripGalleryItem> _bundledTrips = const <TripGalleryItem>[];
  List<TravelArtifact> _bundledArtifacts = const <TravelArtifact>[];
  Map<String, List<JapanMemoryLocation>> _bundledCollections =
      const <String, List<JapanMemoryLocation>>{};

  List<TripGalleryItem> _trips = const <TripGalleryItem>[];
  List<TravelArtifact> _artifacts = const <TravelArtifact>[];
  Map<String, List<JapanMemoryLocation>> _collections =
      const <String, List<JapanMemoryLocation>>{};

  String? _externalMemoriesRoot;
  final Map<String, List<JapanMemoryLocation>> _externalScanCache =
      <String, List<JapanMemoryLocation>>{};

  bool _hasUnsavedChanges = false;

  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get editsGlobalCatalog => kIsWeb;
  String? get globalTripsFileName => _tripsFile.fileName;

  /// Whether this platform can read a real filesystem path at all (i.e.
  /// not web) — gates whether the "External photos root" admin control is
  /// shown.
  bool get supportsExternalMemories => _externalScanner.isSupported;

  /// The real folder (e.g. an SD card mount point) EverAfter should look in
  /// for each trip's `memoriesFolder` subfolder, live at runtime, instead of
  /// requiring photos to be bundled assets. Null/empty means "not
  /// configured" — the catalog falls back to whatever's registered in
  /// `memory_collections.json`, exactly as before this existed.
  String? get externalMemoriesRoot => _externalMemoriesRoot;

  /// Every trip in the catalog, visited or not. Used for routing (NFC/deep
  /// links should still work for a trip that's hidden from the gallery) and
  /// by the admin screen.
  List<TripGalleryItem> get allTrips => _trips;

  /// Only trips marked visited — what the gallery/globe carousel shows.
  List<TripGalleryItem> get trips =>
      _trips.where((trip) => trip.visited).toList(growable: false);

  List<TravelArtifact> get artifacts => _artifacts;

  /// A trip's photo/video locations. Prefers a live scan of
  /// `<externalMemoriesRoot>/<memoriesFolder>/` (cached until
  /// [rescanExternalMemories] is called) when one is configured and finds
  /// anything there; otherwise falls back to what's registered in
  /// `memory_collections.json`.
  List<JapanMemoryLocation> memoryLocationsFor(String tripSlug) {
    final externalLocations = _externalMemoryLocationsFor(tripSlug);
    if (externalLocations != null && externalLocations.isNotEmpty) {
      return externalLocations;
    }
    return _collections[tripSlug] ?? const <JapanMemoryLocation>[];
  }

  List<JapanMemoryLocation>? _externalMemoryLocationsFor(String tripSlug) {
    final root = _externalMemoriesRoot;
    if (!_externalScanner.isSupported || root == null || root.isEmpty) {
      return null;
    }
    final cached = _externalScanCache[tripSlug];
    if (cached != null) {
      return cached;
    }
    TripGalleryItem? trip;
    for (final candidate in _trips) {
      if (candidate.slug == tripSlug) {
        trip = candidate;
        break;
      }
    }
    final memoriesFolder = trip?.memoriesFolder;
    if (trip == null || memoriesFolder == null) {
      return null;
    }
    final scanned = _externalScanner.scan(
      rootPath: root,
      memoriesFolder: memoriesFolder,
      tripName: trip.name,
    );
    _externalScanCache[tripSlug] = scanned;
    return scanned;
  }

  /// Points the catalog at a real folder (e.g. an SD card mount point) to
  /// read photos from live, or clears it back to bundled/registered-only
  /// behavior when [root] is null or empty.
  Future<void> setExternalMemoriesRoot(String? root) async {
    _externalMemoriesRoot = (root == null || root.trim().isEmpty)
        ? null
        : root.trim();
    _externalScanCache.clear();
    final preferences = await SharedPreferences.getInstance();
    if (_externalMemoriesRoot == null) {
      await preferences.remove(_externalMemoriesRootKey);
    } else {
      await preferences.setString(
        _externalMemoriesRootKey,
        _externalMemoriesRoot!,
      );
    }
    notifyListeners();
  }

  /// Forces the next [memoryLocationsFor] call for each trip to re-read the
  /// external root from disk, e.g. after swapping the SD card.
  void rescanExternalMemories() {
    _externalScanCache.clear();
    notifyListeners();
  }

  Future<void> load() async {
    await _loadBundled();

    final preferences = await SharedPreferences.getInstance();
    _externalMemoriesRoot = preferences.getString(_externalMemoriesRootKey);
    _externalScanCache.clear();
    final encodedOverrides = preferences.getString(_deviceOverridesKey);
    if (!kIsWeb && encodedOverrides != null) {
      try {
        final document = jsonDecode(encodedOverrides) as Map<String, dynamic>;
        final overrideTrips = _decodeTrips(
          document['trips'] as List<dynamic>,
        );
        // Merge in any bundled trips that are absent from the saved override.
        // This handles trips added to the catalog after the override was last
        // saved (e.g. a new destination like Yukon) so they appear in the
        // admin and gallery without requiring a manual Reset.
        final overrideSlugs = <String>{
          for (final t in overrideTrips) t.slug,
        };
        _trips = <TripGalleryItem>[
          ...overrideTrips,
          for (final t in _bundledTrips)
            if (!overrideSlugs.contains(t.slug)) t,
        ];
        _artifacts = _decodeArtifacts(document['artifacts'] as List<dynamic>);
        _collections = _decodeCollections(
          document['collections'] as Map<String, dynamic>,
        );
        _hasUnsavedChanges = false;
        notifyListeners();
        return;
      } on Object {
        // Fall through to the bundled catalog below.
      }
    }

    _trips = List<TripGalleryItem>.of(_bundledTrips);
    _artifacts = List<TravelArtifact>.of(_bundledArtifacts);
    _collections = Map<String, List<JapanMemoryLocation>>.of(
      _bundledCollections,
    );
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  Future<void> _loadBundled() async {
    try {
      final contents = await rootBundle.loadString(_bundledTripsPath);
      final document = jsonDecode(contents) as Map<String, dynamic>;
      _bundledTrips = _decodeTrips(document['trips'] as List<dynamic>);
    } on Object {
      _bundledTrips = const <TripGalleryItem>[];
    }
    try {
      final contents = await rootBundle.loadString(_bundledArtifactsPath);
      final document = jsonDecode(contents) as Map<String, dynamic>;
      _bundledArtifacts = _decodeArtifacts(
        document['artifacts'] as List<dynamic>,
      );
    } on Object {
      _bundledArtifacts = const <TravelArtifact>[];
    }
    try {
      final contents = await rootBundle.loadString(_bundledCollectionsPath);
      final document = jsonDecode(contents) as Map<String, dynamic>;
      _bundledCollections = _decodeCollections(
        document['collections'] as Map<String, dynamic>,
      );
    } on Object {
      _bundledCollections = const <String, List<JapanMemoryLocation>>{};
    }
  }

  List<TripGalleryItem> _decodeTrips(List<dynamic> encoded) =>
      <TripGalleryItem>[
        for (final item in encoded)
          TripGalleryItem.fromJson(item as Map<String, dynamic>),
      ];

  List<TravelArtifact> _decodeArtifacts(List<dynamic> encoded) =>
      <TravelArtifact>[
        for (final item in encoded)
          TravelArtifact.fromJson(item as Map<String, dynamic>),
      ];

  Map<String, List<JapanMemoryLocation>> _decodeCollections(
    Map<String, dynamic> encoded,
  ) => <String, List<JapanMemoryLocation>>{
    for (final entry in encoded.entries)
      entry.key: <JapanMemoryLocation>[
        for (final item in entry.value as List<dynamic>)
          JapanMemoryLocation.fromJson(item as Map<String, dynamic>),
      ],
  };

  void setVisited(String tripSlug, bool visited) {
    _trips = <TripGalleryItem>[
      for (final trip in _trips)
        if (trip.slug == tripSlug) trip.copyWith(visited: visited) else trip,
    ];
    _markChanged();
  }

  void updateTrip(TripGalleryItem trip) {
    _trips = <TripGalleryItem>[
      for (final current in _trips)
        if (current.slug == trip.slug) trip else current,
    ];
    _markChanged();
  }

  void setMemoryLocations(
    String tripSlug,
    List<JapanMemoryLocation> locations,
  ) {
    _collections = <String, List<JapanMemoryLocation>>{
      ..._collections,
      tripSlug: locations,
    };
    _markChanged();
  }

  void upsertArtifact(TravelArtifact artifact) {
    final exists = _artifacts.any((item) => item.uid == artifact.uid);
    _artifacts = exists
        ? <TravelArtifact>[
            for (final current in _artifacts)
              if (current.uid == artifact.uid) artifact else current,
          ]
        : <TravelArtifact>[..._artifacts, artifact];
    _markChanged();
  }

  Future<void> save() async {
    if (kIsWeb) {
      _bundledTrips = List<TripGalleryItem>.of(_trips);
      _bundledArtifacts = List<TravelArtifact>.of(_artifacts);
      _bundledCollections = Map<String, List<JapanMemoryLocation>>.of(
        _collections,
      );
      await _tripsFile.save(_encodeTripsDocument(_trips));
      await _artifactsFile.save(_encodeArtifactsDocument(_artifacts));
      await _collectionsFile.save(_encodeCollectionsDocument(_collections));
      _hasUnsavedChanges = false;
      notifyListeners();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _deviceOverridesKey,
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'trips': <Object?>[for (final trip in _trips) trip.toJson()],
        'artifacts': <Object?>[
          for (final artifact in _artifacts) artifact.toJson(),
        ],
        'collections': <String, Object?>{
          for (final entry in _collections.entries)
            entry.key: <Object?>[
              for (final location in entry.value) location.toJson(),
            ],
        },
      }),
    );
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  Future<void> resetToGlobal() async {
    _trips = List<TripGalleryItem>.of(_bundledTrips);
    _artifacts = List<TravelArtifact>.of(_bundledArtifacts);
    _collections = Map<String, List<JapanMemoryLocation>>.of(
      _bundledCollections,
    );
    if (!kIsWeb) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_deviceOverridesKey);
    }
    // On web the global JSON files still need to be written, so mark unsaved.
    // On device the override key was already removed from SharedPreferences, so
    // the next load will use bundled data — nothing left to save.
    _hasUnsavedChanges = kIsWeb;
    notifyListeners();
  }

  void _markChanged() {
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  String _encodeTripsDocument(List<TripGalleryItem> trips) {
    return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schemaVersion': 1,
      'trips': <Object?>[for (final trip in trips) trip.toJson()],
    })}\n';
  }

  String _encodeArtifactsDocument(List<TravelArtifact> artifacts) {
    return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schemaVersion': 1,
      'artifacts': <Object?>[for (final artifact in artifacts) artifact.toJson()],
    })}\n';
  }

  String _encodeCollectionsDocument(
    Map<String, List<JapanMemoryLocation>> collections,
  ) {
    return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schemaVersion': 1,
      'collections': <String, Object?>{
        for (final entry in collections.entries) entry.key: <Object?>[for (final location in entry.value) location.toJson()],
      },
    })}\n';
  }
}

/// Fallback used when a trip has no assigned cover photo yet.
const tripGalleryPlaceholderAsset = publicMemoryPlaceholderAsset;
