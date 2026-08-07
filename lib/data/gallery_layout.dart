import 'dart:convert';
import 'dart:math' as math;

import 'package:everafter/services/global_gallery_layout_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GalleryFrameStyle { oval, circular, portrait, landscape, horizontalOval }

const double horizontalOvalFrameAspectRatio = 25 / 17;
const double circularFrameAspectRatio = 1;
const double featuredCircularFrameSize = 220;

@immutable
class GalleryPhotoEdit {
  const GalleryPhotoEdit({
    required this.assetPath,
    this.alignmentX = 0,
    this.alignmentY = 0,
    this.zoom = 1,
  });

  final String assetPath;
  final double alignmentX;
  final double alignmentY;
  final double zoom;

  GalleryPhotoEdit copyWith({
    double? alignmentX,
    double? alignmentY,
    double? zoom,
  }) {
    return GalleryPhotoEdit(
      assetPath: assetPath,
      alignmentX: alignmentX ?? this.alignmentX,
      alignmentY: alignmentY ?? this.alignmentY,
      zoom: zoom ?? this.zoom,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'assetPath': assetPath,
    'alignmentX': alignmentX,
    'alignmentY': alignmentY,
    'zoom': zoom,
  };

  factory GalleryPhotoEdit.fromJson(Map<String, dynamic> json) {
    return GalleryPhotoEdit(
      assetPath: json['assetPath'] as String,
      alignmentX: (json['alignmentX'] as num?)?.toDouble() ?? 0,
      alignmentY: (json['alignmentY'] as num?)?.toDouble() ?? 0,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1,
    );
  }
}

@immutable
class GalleryFramePlacement {
  const GalleryFramePlacement({
    required this.id,
    required this.memoryIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.style,
    required this.alignmentX,
    required this.alignmentY,
    this.scale = 1,
    this.angle = 0,
    this.portrait = false,
    this.visible = true,
    this.title,
    this.photoAssetPaths = const <String>[],
    this.photoEdits = const <GalleryPhotoEdit>[],
    this.lockAspectRatio = true,
    this.isCustom = false,
  });

  final String id;
  final int memoryIndex;
  final double left;
  final double top;
  final double width;
  final double height;
  final GalleryFrameStyle style;
  final double alignmentX;
  final double alignmentY;
  final double scale;
  final double angle;
  final bool portrait;
  final bool visible;
  final String? title;
  final List<String> photoAssetPaths;
  final List<GalleryPhotoEdit> photoEdits;
  final bool lockAspectRatio;
  final bool isCustom;

  List<GalleryPhotoEdit> get effectivePhotoEdits => photoEdits.isNotEmpty
      ? photoEdits
      : <GalleryPhotoEdit>[
          for (final assetPath in photoAssetPaths)
            GalleryPhotoEdit(assetPath: assetPath),
        ];

  GalleryFramePlacement copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    GalleryFrameStyle? style,
    double? alignmentX,
    double? alignmentY,
    double? scale,
    double? angle,
    bool? portrait,
    bool? visible,
    String? title,
    List<String>? photoAssetPaths,
    List<GalleryPhotoEdit>? photoEdits,
    bool? lockAspectRatio,
    bool? isCustom,
  }) {
    final nextPhotoAssetPaths = photoAssetPaths ?? this.photoAssetPaths;
    return GalleryFramePlacement(
      id: id,
      memoryIndex: memoryIndex,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      style: style ?? this.style,
      alignmentX: alignmentX ?? this.alignmentX,
      alignmentY: alignmentY ?? this.alignmentY,
      scale: scale ?? this.scale,
      angle: angle ?? this.angle,
      portrait: portrait ?? this.portrait,
      visible: visible ?? this.visible,
      title: title ?? this.title,
      photoAssetPaths: nextPhotoAssetPaths,
      photoEdits:
          photoEdits ??
          (photoAssetPaths == null
              ? this.photoEdits
              : <GalleryPhotoEdit>[
                  for (final assetPath in nextPhotoAssetPaths)
                    GalleryPhotoEdit(assetPath: assetPath),
                ]),
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'memoryIndex': memoryIndex,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'style': style.name,
    'alignmentX': alignmentX,
    'alignmentY': alignmentY,
    'scale': scale,
    'angle': angle,
    'portrait': portrait,
    'visible': visible,
    'title': title ?? '',
    'photoAssetPaths': photoAssetPaths,
    'photoEdits': photoEdits.map((edit) => edit.toJson()).toList(),
    'lockAspectRatio': lockAspectRatio,
    'isCustom': isCustom,
  };

  GalleryFramePlacement normalizedOrientation() {
    if (style == GalleryFrameStyle.circular) {
      return this;
    }
    final shouldBeHorizontal =
        style == GalleryFrameStyle.landscape ||
        style == GalleryFrameStyle.horizontalOval;
    final isHorizontal = width >= height;
    if (shouldBeHorizontal == isHorizontal) {
      return this;
    }
    return copyWith(
      width: height,
      height: width,
      portrait: !shouldBeHorizontal,
    );
  }

  GalleryFramePlacement normalizedArtworkAspectRatio() {
    final oriented = normalizedOrientation();
    final targetAspectRatio = switch (oriented.style) {
      GalleryFrameStyle.horizontalOval => horizontalOvalFrameAspectRatio,
      GalleryFrameStyle.circular => circularFrameAspectRatio,
      _ => null,
    };
    if (targetAspectRatio == null ||
        (oriented.width / oriented.height - targetAspectRatio).abs() < 0.001) {
      return oriented;
    }
    final centerY = oriented.top + oriented.height / 2;
    final correctedHeight = oriented.width / targetAspectRatio;
    return oriented.copyWith(
      top: centerY - correctedHeight / 2,
      height: correctedHeight,
      portrait: false,
    );
  }

  factory GalleryFramePlacement.fromJson(Map<String, dynamic> json) {
    return GalleryFramePlacement(
      id: json['id'] as String,
      memoryIndex: json['memoryIndex'] as int,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      style: GalleryFrameStyle.values.byName(json['style'] as String),
      alignmentX: (json['alignmentX'] as num).toDouble(),
      alignmentY: (json['alignmentY'] as num).toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      portrait: json['portrait'] as bool? ?? false,
      visible: json['visible'] as bool? ?? true,
      title: switch (json['title']) {
        final String value when value.isNotEmpty => value,
        _ => null,
      },
      photoAssetPaths:
          (json['photoAssetPaths'] as List<dynamic>? ?? <dynamic>[])
              .cast<String>(),
      photoEdits: (json['photoEdits'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) => GalleryPhotoEdit.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      lockAspectRatio: json['lockAspectRatio'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
    ).normalizedArtworkAspectRatio();
  }

  GalleryFramePlacement resized({double? width, double? height}) {
    if (!lockAspectRatio || (width == null && height == null)) {
      return copyWith(width: width, height: height);
    }
    final aspectRatio = this.width / this.height;
    if (width != null) {
      return copyWith(width: width, height: width / aspectRatio);
    }
    return copyWith(width: height! * aspectRatio, height: height);
  }
}

@immutable
class GalleryTrinketPlacement {
  const GalleryTrinketPlacement({
    required this.id,
    required this.assetName,
    required this.label,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.angle = 0,
    this.visible = true,
    this.isCustom = false,
  });

  final String id;
  final String assetName;
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;
  final bool visible;
  final bool isCustom;

  GalleryTrinketPlacement copyWith({
    String? assetName,
    double? left,
    double? top,
    double? width,
    double? height,
    double? angle,
    bool? visible,
    bool? isCustom,
  }) {
    return GalleryTrinketPlacement(
      id: id,
      assetName: assetName ?? this.assetName,
      label: label,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      angle: angle ?? this.angle,
      visible: visible ?? this.visible,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'assetName': assetName,
    'label': label,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'angle': angle,
    'visible': visible,
    'isCustom': isCustom,
  };

  factory GalleryTrinketPlacement.fromJson(Map<String, dynamic> json) {
    return GalleryTrinketPlacement(
      id: json['id'] as String,
      assetName: json['assetName'] as String,
      label: json['label'] as String,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      visible: json['visible'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

@immutable
class GalleryDecorationPlacement {
  const GalleryDecorationPlacement({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.angle = 0,
  });

  final String id;
  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;

  GalleryDecorationPlacement copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    double? angle,
  }) {
    return GalleryDecorationPlacement(
      id: id,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      angle: angle ?? this.angle,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'angle': angle,
  };

  factory GalleryDecorationPlacement.fromJson(Map<String, dynamic> json) {
    return GalleryDecorationPlacement(
      id: json['id'] as String,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
    );
  }
}

@immutable
class GalleryInstagramPlacement {
  const GalleryInstagramPlacement({
    required this.id,
    required this.postIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.style,
    required this.angle,
    this.scale = 1.5,
    this.visible = true,
  });

  final String id;
  final int postIndex;
  final double left;
  final double top;
  final double width;
  final double height;
  final GalleryFrameStyle style;
  final double angle;
  final double scale;
  final bool visible;

  GalleryInstagramPlacement copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    GalleryFrameStyle? style,
    double? angle,
    double? scale,
    bool? visible,
  }) {
    return GalleryInstagramPlacement(
      id: id,
      postIndex: postIndex,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      style: style ?? this.style,
      angle: angle ?? this.angle,
      scale: scale ?? this.scale,
      visible: visible ?? this.visible,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'postIndex': postIndex,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'style': style.name,
    'angle': angle,
    'scale': scale,
    'visible': visible,
  };

  factory GalleryInstagramPlacement.fromJson(Map<String, dynamic> json) {
    return GalleryInstagramPlacement(
      id: json['id'] as String,
      postIndex: json['postIndex'] as int,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      style: GalleryFrameStyle.values.byName(json['style'] as String),
      angle: 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.5,
      visible: json['visible'] as bool? ?? true,
    );
  }
}

@immutable
class GalleryTripLayout {
  const GalleryTripLayout({
    required this.frames,
    required this.trinkets,
    required this.instagramPosts,
    required this.stripWidth,
    required this.foodMenu,
    this.leadingTrim = 0,
    this.travelStartDate,
    this.travelEndDate,
    this.layoutVersion = 2,
  });

  final List<GalleryFramePlacement> frames;
  final List<GalleryTrinketPlacement> trinkets;
  final List<GalleryInstagramPlacement> instagramPosts;
  final double stripWidth;
  final GalleryDecorationPlacement foodMenu;
  final double leadingTrim;
  final String? travelStartDate;
  final String? travelEndDate;
  final int layoutVersion;

  DateTime? get travelStart => DateTime.tryParse(travelStartDate ?? '');
  DateTime? get travelEnd => DateTime.tryParse(travelEndDate ?? '');

  String? effectiveStartDateLabel(String? fallback) {
    final date = travelStart;
    return date == null ? fallback : formatGalleryTravelDate(date);
  }

  String? effectiveEndDateLabel(String? fallback) {
    final date = travelEnd;
    return date == null ? fallback : formatGalleryTravelDate(date);
  }

  String effectiveDateRangeLabel(String fallback) {
    final start = travelStart;
    final end = travelEnd;
    return start != null && end != null
        ? '${formatGalleryTravelDate(start)}  →  '
              '${formatGalleryTravelDate(end)}'
        : fallback;
  }

  String? effectiveDurationLabel(int? fallbackDays) {
    final start = travelStart;
    final end = travelEnd;
    if (start != null && end != null) {
      return '${end.difference(start).inDays + 1} DAYS';
    }
    return fallbackDays == null ? null : '$fallbackDays DAYS';
  }

  GalleryTripLayout copyWith({
    List<GalleryFramePlacement>? frames,
    List<GalleryTrinketPlacement>? trinkets,
    List<GalleryInstagramPlacement>? instagramPosts,
    double? stripWidth,
    GalleryDecorationPlacement? foodMenu,
    double? leadingTrim,
    String? travelStartDate,
    String? travelEndDate,
    int? layoutVersion,
    bool clearTravelDates = false,
  }) {
    return GalleryTripLayout(
      frames: frames ?? this.frames,
      trinkets: trinkets ?? this.trinkets,
      instagramPosts: instagramPosts ?? this.instagramPosts,
      stripWidth: stripWidth ?? this.stripWidth,
      foodMenu: foodMenu ?? this.foodMenu,
      leadingTrim: leadingTrim ?? this.leadingTrim,
      travelStartDate: clearTravelDates
          ? null
          : travelStartDate ?? this.travelStartDate,
      travelEndDate: clearTravelDates
          ? null
          : travelEndDate ?? this.travelEndDate,
      layoutVersion: layoutVersion ?? this.layoutVersion,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'frames': frames.map((frame) => frame.toJson()).toList(),
    'trinkets': trinkets.map((trinket) => trinket.toJson()).toList(),
    'instagramPosts': instagramPosts.map((post) => post.toJson()).toList(),
    'stripWidth': stripWidth,
    'foodMenu': foodMenu.toJson(),
    'leadingTrim': leadingTrim,
    'travelStartDate': travelStartDate,
    'travelEndDate': travelEndDate,
    'layoutVersion': layoutVersion,
  };

  factory GalleryTripLayout.fromJson(
    Map<String, dynamic> json, {
    required String tripSlug,
    required double fallbackStripWidth,
  }) {
    final layout = GalleryTripLayout(
      frames: (json['frames'] as List<dynamic>)
          .map(
            (item) =>
                GalleryFramePlacement.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      stripWidth:
          (json['stripWidth'] as num?)?.toDouble() ?? fallbackStripWidth,
      trinkets: (json['trinkets'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) =>
                GalleryTrinketPlacement.fromJson(item as Map<String, dynamic>),
          )
          .where((item) => _isLocalTrinketSource(item.assetName))
          .toList(),
      instagramPosts:
          (json['instagramPosts'] as List<dynamic>?)
              ?.map(
                (item) => GalleryInstagramPlacement.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          defaultInstagramPlacementsFor(tripSlug),
      foodMenu: switch (json['foodMenu']) {
        final Map<String, dynamic> value => GalleryDecorationPlacement.fromJson(
          value,
        ),
        _ => defaultFoodMenuPlacementFor(tripSlug),
      },
      leadingTrim: (json['leadingTrim'] as num?)?.toDouble() ?? 0,
      travelStartDate: json['travelStartDate'] as String?,
      travelEndDate: json['travelEndDate'] as String?,
      layoutVersion: (json['layoutVersion'] as num?)?.toInt() ?? 1,
    );
    final instagramUpgraded = tripSlug == 'japan' && layout.layoutVersion < 2
        ? _upgradeJapanInstagramFrameScale(layout)
        : layout;
    final circularUpgraded = instagramUpgraded.layoutVersion < 3
        ? _upgradeCircularFrameMix(instagramUpgraded)
        : instagramUpgraded;
    return circularUpgraded.layoutVersion < 4
        ? _upgradeFeaturedCircularFrameSize(circularUpgraded)
        : circularUpgraded;
  }
}

GalleryTripLayout _upgradeJapanInstagramFrameScale(GalleryTripLayout layout) {
  final posts = layout.instagramPosts;

  double addedWidth(GalleryInstagramPlacement post) =>
      post.width * (post.scale - 1);

  double shiftBefore(double left) => posts
      .where((post) => post.left < left)
      .fold(0, (shift, post) => shift + addedWidth(post));

  final totalAddedWidth = posts.fold(
    0.0,
    (shift, post) => shift + addedWidth(post),
  );

  return layout.copyWith(
    frames: <GalleryFramePlacement>[
      for (final frame in layout.frames)
        frame.copyWith(left: frame.left + shiftBefore(frame.left)),
    ],
    trinkets: <GalleryTrinketPlacement>[
      for (final trinket in layout.trinkets)
        trinket.copyWith(left: trinket.left + shiftBefore(trinket.left)),
    ],
    instagramPosts: <GalleryInstagramPlacement>[
      for (final post in posts)
        post.copyWith(
          left: post.left + shiftBefore(post.left) + addedWidth(post) / 2,
        ),
    ],
    stripWidth: layout.stripWidth + totalAddedWidth,
    foodMenu: layout.foodMenu.copyWith(
      left: layout.foodMenu.left + shiftBefore(layout.foodMenu.left),
    ),
    layoutVersion: 2,
  );
}

GalleryTripLayout _upgradeCircularFrameMix(GalleryTripLayout layout) {
  GalleryFramePlacement circularFrame(GalleryFramePlacement frame) {
    if (frame.id != 'frame-2' && frame.id != 'frame-8') {
      return frame;
    }
    final size = math.min(frame.width, frame.height);
    final centerY = frame.top + frame.height / 2;
    return frame.copyWith(
      top: centerY - size / 2,
      width: size,
      height: size,
      style: GalleryFrameStyle.circular,
      portrait: false,
    );
  }

  GalleryInstagramPlacement circularPost(GalleryInstagramPlacement post) {
    if (post.id != 'instagram-3' && post.id != 'instagram-6') {
      return post;
    }
    final size = math.min(post.width, post.height);
    final centerY = post.top + post.height / 2;
    return post.copyWith(
      top: centerY - size / 2,
      width: size,
      height: size,
      style: GalleryFrameStyle.circular,
    );
  }

  return layout.copyWith(
    frames: layout.frames.map(circularFrame).toList(growable: false),
    instagramPosts: layout.instagramPosts
        .map(circularPost)
        .toList(growable: false),
    layoutVersion: 3,
  );
}

GalleryTripLayout _upgradeFeaturedCircularFrameSize(GalleryTripLayout layout) {
  final firstCircle = layout.frames
      .where((frame) => frame.id == 'frame-2')
      .firstOrNull;
  final secondCircle = layout.frames
      .where((frame) => frame.id == 'frame-8')
      .firstOrNull;
  final reflowJapanWall =
      layout.instagramPosts.isNotEmpty &&
      firstCircle != null &&
      secondCircle != null;

  double reflowOffset(double left) {
    if (!reflowJapanWall) {
      return 0;
    }
    var offset = 0.0;
    if (left > firstCircle.left) {
      offset += 105;
    }
    if (left > secondCircle.left) {
      offset += 130;
    }
    return offset;
  }

  GalleryFramePlacement enlargeFeaturedCircle(GalleryFramePlacement frame) {
    if ((frame.id != 'frame-2' && frame.id != 'frame-8') ||
        frame.style != GalleryFrameStyle.circular) {
      return frame;
    }
    final centerX = frame.left + frame.width / 2;
    final centerY = frame.top + frame.height / 2;
    final horizontalNudge = layout.instagramPosts.isEmpty
        ? 0.0
        : frame.id == 'frame-8'
        ? 40.0
        : 24.0;
    return frame.copyWith(
      left:
          centerX -
          featuredCircularFrameSize / 2 +
          horizontalNudge +
          reflowOffset(frame.left),
      top: centerY - featuredCircularFrameSize / 2,
      width: featuredCircularFrameSize,
      height: featuredCircularFrameSize,
    );
  }

  return layout.copyWith(
    frames: <GalleryFramePlacement>[
      for (final frame in layout.frames)
        if (frame.id == 'frame-2' || frame.id == 'frame-8')
          enlargeFeaturedCircle(frame)
        else
          frame.copyWith(left: frame.left + reflowOffset(frame.left)),
    ],
    trinkets: <GalleryTrinketPlacement>[
      for (final trinket in layout.trinkets)
        trinket.copyWith(left: trinket.left + reflowOffset(trinket.left)),
    ],
    instagramPosts: <GalleryInstagramPlacement>[
      for (final post in layout.instagramPosts)
        post.copyWith(left: post.left + reflowOffset(post.left)),
    ],
    foodMenu: layout.foodMenu.copyWith(
      left: layout.foodMenu.left + reflowOffset(layout.foodMenu.left),
    ),
    stripWidth: layout.stripWidth + (reflowJapanWall ? 235 : 0),
    layoutVersion: 4,
  );
}

class GalleryLayoutStore extends ChangeNotifier {
  GalleryLayoutStore._() : _globalFile = createGlobalGalleryLayoutFile();

  static final GalleryLayoutStore instance = GalleryLayoutStore._();
  static const String bundledGlobalLayoutPath =
      'assets/data/gallery_layouts.json';
  static const String _legacyStorageKey = 'everafter.gallery-layout.v1';
  static const String _deviceOverridesKey =
      'everafter.gallery-layout.device-overrides.v1';

  final GlobalGalleryLayoutFile _globalFile;
  Map<String, GalleryTripLayout> _bundledLayouts =
      <String, GalleryTripLayout>{};
  Map<String, GalleryTripLayout> _globalLayouts = <String, GalleryTripLayout>{};
  Map<String, Map<String, dynamic>> _deviceOverrides =
      <String, Map<String, dynamic>>{};
  Map<String, GalleryTripLayout> _layouts = <String, GalleryTripLayout>{};
  bool _hasUnsavedChanges = false;

  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get editsGlobalLayout => kIsWeb;
  String? get globalSourceFileName => _globalFile.fileName;

  GalleryTripLayout layoutFor(String tripSlug) =>
      _layouts[tripSlug] ?? defaultGalleryLayoutFor(tripSlug);

  Future<void> load() async {
    await _loadBundledGlobalLayouts();
    final preferences = await SharedPreferences.getInstance();
    _deviceOverrides = <String, Map<String, dynamic>>{};

    final encodedOverrides = preferences.getString(_deviceOverridesKey);
    if (!kIsWeb && encodedOverrides != null) {
      try {
        final document = jsonDecode(encodedOverrides) as Map<String, dynamic>;
        final overrides = document['overrides'] as Map? ?? document;
        _deviceOverrides = <String, Map<String, dynamic>>{
          for (final entry in overrides.entries)
            entry.key as String: Map<String, dynamic>.from(entry.value as Map),
        };
      } on Object {
        _deviceOverrides = <String, Map<String, dynamic>>{};
      }
    } else if (!kIsWeb) {
      final legacy = preferences.getString(_legacyStorageKey);
      if (legacy != null) {
        try {
          final legacyLayouts = _decodeLayouts(
            jsonDecode(legacy) as Map<String, dynamic>,
          );
          _deviceOverrides = _createOverrides(legacyLayouts);
          await _cacheDeviceOverrides(preferences);
          await preferences.remove(_legacyStorageKey);
        } on Object {
          // A malformed legacy snapshot must not hide the bundled global file.
        }
      }
    }

    _layouts = kIsWeb ? Map.of(_globalLayouts) : _effectiveDeviceLayouts();
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  void updateFrame(String tripSlug, GalleryFramePlacement frame) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        frames: <GalleryFramePlacement>[
          for (final current in layout.frames)
            if (current.id == frame.id) frame else current,
        ],
      ),
    };
    _markChanged();
  }

  GalleryFramePlacement addFrame(String tripSlug) {
    final layout = layoutFor(tripSlug);
    final frame = GalleryFramePlacement(
      id: _nextCustomId('custom-frame', layout.frames.map((item) => item.id)),
      memoryIndex:
          layout.frames.map((item) => item.memoryIndex).fold(0, math.max) + 1,
      left: layout.leadingTrim + 640,
      top: 269,
      width: 190,
      height: 272,
      style: GalleryFrameStyle.oval,
      alignmentX: 0,
      alignmentY: 0,
      portrait: true,
      title: 'Untitled memory',
      isCustom: true,
    );
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        frames: <GalleryFramePlacement>[...layout.frames, frame],
      ),
    };
    _markChanged();
    return frame;
  }

  void removeFrame(String tripSlug, String frameId) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        frames: layout.frames
            .where((item) => item.id != frameId)
            .toList(growable: false),
      ),
    };
    _markChanged();
  }

  void updateTrinket(String tripSlug, GalleryTrinketPlacement trinket) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        trinkets: <GalleryTrinketPlacement>[
          for (final current in layout.trinkets)
            if (current.id == trinket.id) trinket else current,
        ],
      ),
    };
    _markChanged();
  }

  GalleryTrinketPlacement addTrinket(
    String tripSlug, {
    required String assetName,
    required String label,
  }) {
    final layout = layoutFor(tripSlug);
    final trinket = GalleryTrinketPlacement(
      id: _nextCustomId(
        'custom-trinket',
        layout.trinkets.map((item) => item.id),
      ),
      assetName: assetName,
      label: label,
      left: layout.leadingTrim + 510,
      top: 230,
      width: 300,
      height: 340,
      isCustom: true,
    );
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        trinkets: <GalleryTrinketPlacement>[...layout.trinkets, trinket],
      ),
    };
    _markChanged();
    return trinket;
  }

  void removeTrinket(String tripSlug, String trinketId) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        trinkets: layout.trinkets
            .where((item) => item.id != trinketId)
            .toList(growable: false),
      ),
    };
    _markChanged();
  }

  void updateFoodMenu(String tripSlug, GalleryDecorationPlacement foodMenu) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(foodMenu: foodMenu),
    };
    _markChanged();
  }

  void updateInstagramPost(
    String tripSlug,
    GalleryInstagramPlacement instagramPost,
  ) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        instagramPosts: <GalleryInstagramPlacement>[
          for (final current in layout.instagramPosts)
            if (current.id == instagramPost.id)
              instagramPost.copyWith(angle: 0)
            else
              current,
        ],
      ),
    };
    _markChanged();
  }

  void updateTravelDates(
    String tripSlug, {
    required DateTime? start,
    required DateTime? end,
  }) {
    final layout = layoutFor(tripSlug);
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        travelStartDate: start == null ? null : _dateOnlyIso(start),
        travelEndDate: end == null ? null : _dateOnlyIso(end),
        clearTravelDates: start == null || end == null,
      ),
    };
    _markChanged();
  }

  void fitTripToContents(String tripSlug) {
    final layout = layoutFor(tripSlug);
    const gutter = 50.0;
    var leftEdge = tripSlug == 'japan' ? 3635.0 : 3070.0;
    var rightEdge = leftEdge + 340;
    leftEdge = math.min(leftEdge, layout.foodMenu.left);
    rightEdge = math.max(
      rightEdge,
      layout.foodMenu.left + layout.foodMenu.width,
    );
    for (final frame in layout.frames.where((item) => item.visible)) {
      final renderedWidth = frame.width * 2.3 * frame.scale;
      leftEdge = math.min(
        leftEdge,
        frame.left - (renderedWidth - frame.width) / 2,
      );
      rightEdge = math.max(
        rightEdge,
        frame.left + (renderedWidth + frame.width) / 2,
      );
    }
    for (final trinket in layout.trinkets.where((item) => item.visible)) {
      leftEdge = math.min(leftEdge, trinket.left);
      rightEdge = math.max(rightEdge, trinket.left + trinket.width);
    }
    for (final post in layout.instagramPosts.where((item) => item.visible)) {
      final renderedWidth = post.width * post.scale;
      leftEdge = math.min(
        leftEdge,
        post.left - (renderedWidth - post.width) / 2,
      );
      rightEdge = math.max(
        rightEdge,
        post.left + (renderedWidth + post.width) / 2,
      );
    }
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: layout.copyWith(
        leadingTrim: leftEdge - gutter,
        stripWidth: rightEdge - leftEdge + gutter * 2,
      ),
    };
    _markChanged();
  }

  Future<void> save() async {
    if (kIsWeb) {
      _globalLayouts = Map<String, GalleryTripLayout>.of(_layouts);
      await _globalFile.save(encodeGlobalGalleryLayoutDocument(_globalLayouts));
      _hasUnsavedChanges = false;
      notifyListeners();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    _deviceOverrides = _createOverrides(_layouts);
    await _cacheDeviceOverrides(preferences);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  Map<String, GalleryTripLayout> _decodeLayouts(Map<String, dynamic> encoded) {
    return encoded.map(
      (slug, value) => MapEntry(
        slug,
        GalleryTripLayout.fromJson(
          Map<String, dynamic>.from(value as Map),
          tripSlug: slug,
          fallbackStripWidth: defaultGalleryStripWidthFor(slug),
        ),
      ),
    );
  }

  Future<void> _cacheDeviceOverrides(SharedPreferences preferences) {
    return preferences.setString(
      _deviceOverridesKey,
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'overrides': _deviceOverrides,
      }),
    );
  }

  Future<void> resetTrip(String tripSlug) async {
    _layouts = <String, GalleryTripLayout>{
      ..._layouts,
      tripSlug: kIsWeb
          ? (_bundledLayouts[tripSlug] ?? defaultGalleryLayoutFor(tripSlug))
          : _globalLayoutFor(tripSlug),
    };
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<void> _loadBundledGlobalLayouts() async {
    try {
      final contents = await rootBundle.loadString(bundledGlobalLayoutPath);
      _bundledLayouts = decodeGlobalGalleryLayoutDocument(contents);
    } on Object {
      _bundledLayouts = <String, GalleryTripLayout>{};
    }
    _globalLayouts = Map<String, GalleryTripLayout>.of(_bundledLayouts);
  }

  GalleryTripLayout _globalLayoutFor(String tripSlug) =>
      _globalLayouts[tripSlug] ?? defaultGalleryLayoutFor(tripSlug);

  Map<String, GalleryTripLayout> _effectiveDeviceLayouts() {
    final slugs = <String>{..._globalLayouts.keys, ..._deviceOverrides.keys};
    return <String, GalleryTripLayout>{
      for (final slug in slugs)
        slug: _layoutWithPatch(
          slug,
          _globalLayoutFor(slug),
          _deviceOverrides[slug],
        ),
    };
  }

  Map<String, Map<String, dynamic>> _createOverrides(
    Map<String, GalleryTripLayout> layouts,
  ) {
    final overrides = <String, Map<String, dynamic>>{};
    for (final entry in layouts.entries) {
      final patch = _jsonMapDifference(
        _globalLayoutFor(entry.key).toJson(),
        entry.value.toJson(),
      );
      if (patch.isNotEmpty) overrides[entry.key] = patch;
    }
    return overrides;
  }

  GalleryTripLayout _layoutWithPatch(
    String tripSlug,
    GalleryTripLayout global,
    Map<String, dynamic>? patch,
  ) {
    if (patch == null || patch.isEmpty) return global;
    final merged = _mergeJsonMaps(global.toJson(), patch);
    return GalleryTripLayout.fromJson(
      merged,
      tripSlug: tripSlug,
      fallbackStripWidth: global.stripWidth,
    );
  }

  void _markChanged() {
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  String _nextCustomId(String prefix, Iterable<String> existingIds) {
    final existing = existingIds.toSet();
    var index = 1;
    while (existing.contains('$prefix-$index')) {
      index += 1;
    }
    return '$prefix-$index';
  }
}

Map<String, GalleryTripLayout> decodeGlobalGalleryLayoutDocument(
  String contents,
) {
  final document = jsonDecode(contents);
  if (document is! Map<String, dynamic>) {
    throw const FormatException('Global gallery layout must be a JSON object.');
  }
  if (document['schemaVersion'] != 1) {
    throw const FormatException('Unsupported global gallery layout schema.');
  }
  final encodedLayouts = document['layouts'];
  if (encodedLayouts is! Map) {
    throw const FormatException('Global gallery layout is missing layouts.');
  }
  return <String, GalleryTripLayout>{
    for (final entry in encodedLayouts.entries)
      entry.key as String: GalleryTripLayout.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
        tripSlug: entry.key as String,
        fallbackStripWidth: defaultGalleryStripWidthFor(entry.key as String),
      ),
  };
}

String encodeGlobalGalleryLayoutDocument(
  Map<String, GalleryTripLayout> layouts,
) {
  return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'schemaVersion': 1,
    'layouts': <String, Object?>{for (final entry in layouts.entries) entry.key: entry.value.toJson()},
  })}\n';
}

Map<String, dynamic> _jsonMapDifference(
  Map<String, dynamic> global,
  Map<String, dynamic> device,
) {
  final difference = <String, dynamic>{};
  for (final entry in device.entries) {
    final globalValue = global[entry.key];
    final deviceValue = entry.value;
    if (globalValue is Map && deviceValue is Map) {
      final nested = _jsonMapDifference(
        Map<String, dynamic>.from(globalValue),
        Map<String, dynamic>.from(deviceValue),
      );
      if (nested.isNotEmpty) difference[entry.key] = nested;
    } else if (!_jsonValuesEqual(globalValue, deviceValue)) {
      difference[entry.key] = deviceValue;
    }
  }
  return difference;
}

Map<String, dynamic> _mergeJsonMaps(
  Map<String, dynamic> global,
  Map<String, dynamic> patch,
) {
  final merged = Map<String, dynamic>.from(global);
  for (final entry in patch.entries) {
    final globalValue = merged[entry.key];
    final patchValue = entry.value;
    if (globalValue is Map && patchValue is Map) {
      merged[entry.key] = _mergeJsonMaps(
        Map<String, dynamic>.from(globalValue),
        Map<String, dynamic>.from(patchValue),
      );
    } else {
      merged[entry.key] = patchValue;
    }
  }
  return merged;
}

bool _jsonValuesEqual(Object? first, Object? second) =>
    jsonEncode(first) == jsonEncode(second);

bool _isLocalTrinketSource(String source) =>
    source.startsWith('assets/') ||
    source.startsWith('data:image/png;base64,') ||
    source.startsWith('data:image/jpeg;base64,') ||
    source.startsWith('data:image/webp;base64,');

GalleryTripLayout defaultGalleryLayoutFor(String tripSlug) {
  const rowCenterY = 405.0;
  const baseFrames = <GalleryFramePlacement>[
    GalleryFramePlacement(
      id: 'frame-0',
      memoryIndex: 0,
      left: 135,
      top: rowCenterY - 136,
      width: 190,
      height: 272,
      style: GalleryFrameStyle.oval,
      alignmentX: 0.15,
      alignmentY: -0.2,
      portrait: true,
    ),
    GalleryFramePlacement(
      id: 'frame-1',
      memoryIndex: 1,
      left: 576,
      top: rowCenterY - 127,
      width: 178,
      height: 254,
      style: GalleryFrameStyle.portrait,
      alignmentX: -0.22,
      alignmentY: -0.05,
      portrait: true,
    ),
    GalleryFramePlacement(
      id: 'frame-2',
      memoryIndex: 2,
      left: 970,
      top: rowCenterY - 110,
      width: featuredCircularFrameSize,
      height: featuredCircularFrameSize,
      style: GalleryFrameStyle.circular,
      alignmentX: 0.28,
      alignmentY: -0.18,
    ),
    GalleryFramePlacement(
      id: 'frame-3',
      memoryIndex: 3,
      left: 1443,
      top: rowCenterY - 93,
      width: 232,
      height: 186,
      style: GalleryFrameStyle.horizontalOval,
      alignmentX: 0.2,
      alignmentY: 0.08,
    ),
    GalleryFramePlacement(
      id: 'frame-4',
      memoryIndex: 4,
      left: 2225,
      top: rowCenterY - 128.5,
      width: 180,
      height: 257,
      style: GalleryFrameStyle.portrait,
      alignmentX: -0.28,
      alignmentY: 0.08,
      portrait: true,
    ),
    GalleryFramePlacement(
      id: 'frame-5',
      memoryIndex: 5,
      left: 2685,
      top: rowCenterY - 90.5,
      width: 226,
      height: 181,
      style: GalleryFrameStyle.landscape,
      alignmentX: 0.26,
      alignmentY: -0.08,
    ),
    GalleryFramePlacement(
      id: 'frame-6',
      memoryIndex: 6,
      left: 3570,
      top: rowCenterY - 90.5,
      width: 226,
      height: 181,
      style: GalleryFrameStyle.landscape,
      alignmentX: -0.18,
      alignmentY: 0.14,
    ),
    GalleryFramePlacement(
      id: 'frame-7',
      memoryIndex: 7,
      left: 4075,
      top: rowCenterY - 127,
      width: 178,
      height: 254,
      style: GalleryFrameStyle.portrait,
      alignmentX: 0.2,
      alignmentY: -0.12,
      portrait: true,
    ),
    GalleryFramePlacement(
      id: 'frame-8',
      memoryIndex: 8,
      left: 4463,
      top: rowCenterY - 110,
      width: featuredCircularFrameSize,
      height: featuredCircularFrameSize,
      style: GalleryFrameStyle.circular,
      alignmentX: -0.2,
      alignmentY: 0.12,
    ),
    GalleryFramePlacement(
      id: 'frame-9',
      memoryIndex: 9,
      left: 4920,
      top: rowCenterY - 89,
      width: 222,
      height: 178,
      style: GalleryFrameStyle.horizontalOval,
      alignmentX: 0.18,
      alignmentY: 0.12,
    ),
    GalleryFramePlacement(
      id: 'frame-10',
      memoryIndex: 10,
      left: 5420,
      top: rowCenterY - 128.5,
      width: 180,
      height: 257,
      style: GalleryFrameStyle.oval,
      alignmentX: 0.08,
      alignmentY: -0.16,
      portrait: true,
    ),
    GalleryFramePlacement(
      id: 'frame-11',
      memoryIndex: 11,
      left: 5845,
      top: rowCenterY - 125.5,
      width: 176,
      height: 251,
      style: GalleryFrameStyle.portrait,
      alignmentX: 0.22,
      alignmentY: 0.04,
      portrait: true,
    ),
  ];

  final frames = switch (tripSlug) {
    'japan' => <GalleryFramePlacement>[
      baseFrames[0].copyWith(scale: 0.90 * 1.10, angle: -0.012),
      baseFrames[1].copyWith(left: 1193, scale: 1.08 * 1.10, angle: 0.014),
      baseFrames[2].copyWith(left: 1947, scale: 0.92 * 1.10, angle: -0.01),
      baseFrames[3].copyWith(left: 2877, scale: 1.07 * 1.10, angle: 0.01),
      baseFrames[4].copyWith(left: 4125, scale: 0.96 * 1.10, angle: 0.012),
      baseFrames[5].copyWith(left: 4931, scale: 1.04 * 1.10, angle: -0.008),
      baseFrames[6].copyWith(left: 5539, scale: 1.02 * 1.10, angle: 0.009),
      baseFrames[7].copyWith(left: 6511, scale: 0.92 * 1.10, angle: -0.013),
      baseFrames[8].copyWith(left: 6968, scale: 1.08 * 1.10, angle: 0.008),
      baseFrames[9].copyWith(left: 7768, scale: 1.04 * 1.10, angle: -0.008),
      baseFrames[10].copyWith(left: 8314, scale: 0.94 * 1.10, angle: 0.011),
      baseFrames[11].copyWith(left: 8784, scale: 1.07 * 1.10, angle: -0.01),
    ],
    'south-korea' => <GalleryFramePlacement>[
      for (final frame in baseFrames)
        frame.copyWith(visible: frame.memoryIndex < 5),
    ],
    _ => baseFrames,
  };

  final trinkets = tripSlug == 'south-korea'
      ? const <GalleryTrinketPlacement>[
          GalleryTrinketPlacement(
            id: 'demo-keepsake-1',
            assetName: 'assets/images/experience/china-nfc-magnet-reveal.png',
            label: 'Demo keepsake one',
            left: 2515,
            top: 242,
            width: 470,
            height: 326,
          ),
          GalleryTrinketPlacement(
            id: 'demo-keepsake-2',
            assetName:
                'assets/images/experience/hong-kong-nfc-magnet-reveal.png',
            label: 'Demo keepsake two',
            left: 3360,
            top: 197.5,
            width: 280,
            height: 415,
          ),
          GalleryTrinketPlacement(
            id: 'demo-keepsake-3',
            assetName:
                'assets/images/experience/japan-nfc-magnet-reveal-fox.png',
            label: 'Demo keepsake three',
            left: 4015,
            top: 228,
            width: 470,
            height: 354,
          ),
          GalleryTrinketPlacement(
            id: 'demo-keepsake-4',
            assetName:
                'assets/images/experience/taiwan-nfc-magnet-reveal-bubble-tea.png',
            label: 'Demo keepsake four',
            left: 4860,
            top: 194.5,
            width: 280,
            height: 421,
          ),
          GalleryTrinketPlacement(
            id: 'demo-keepsake-5',
            assetName:
                'assets/images/experience/vietnam-nfc-magnet-reveal-lotus.png',
            label: 'Demo keepsake five',
            left: 5555,
            top: 206.5,
            width: 390,
            height: 397,
          ),
        ]
      : const <GalleryTrinketPlacement>[];

  final layout = GalleryTripLayout(
    frames: <GalleryFramePlacement>[
      for (final frame in frames) frame.normalizedArtworkAspectRatio(),
    ],
    trinkets: trinkets,
    instagramPosts: defaultInstagramPlacementsFor(tripSlug),
    stripWidth: defaultGalleryStripWidthFor(tripSlug),
    foodMenu: defaultFoodMenuPlacementFor(tripSlug),
    leadingTrim: 0,
    layoutVersion: tripSlug == 'japan' ? 1 : 2,
  );
  final instagramUpgraded = tripSlug == 'japan'
      ? _upgradeJapanInstagramFrameScale(layout)
      : layout;
  return _upgradeFeaturedCircularFrameSize(
    _upgradeCircularFrameMix(instagramUpgraded),
  );
}

List<GalleryInstagramPlacement> defaultInstagramPlacementsFor(String tripSlug) {
  if (tripSlug != 'japan') {
    return const <GalleryInstagramPlacement>[];
  }
  return const <GalleryInstagramPlacement>[
    GalleryInstagramPlacement(
      id: 'instagram-0',
      postIndex: 0,
      left: 470,
      top: 205,
      width: 272,
      height: 400,
      style: GalleryFrameStyle.oval,
      angle: 0,
    ),
    GalleryInstagramPlacement(
      id: 'instagram-1',
      postIndex: 1,
      left: 1545,
      top: 205,
      width: 272,
      height: 400,
      style: GalleryFrameStyle.portrait,
      angle: 0,
    ),
    GalleryInstagramPlacement(
      id: 'instagram-2',
      postIndex: 2,
      left: 2255,
      top: 269,
      width: 400,
      height: 272,
      style: GalleryFrameStyle.horizontalOval,
      angle: 0,
    ),
    GalleryInstagramPlacement(
      id: 'instagram-3',
      postIndex: 3,
      left: 3335,
      top: 269,
      width: 272,
      height: 272,
      style: GalleryFrameStyle.circular,
      angle: 0,
    ),
    GalleryInstagramPlacement(
      id: 'instagram-4',
      postIndex: 4,
      left: 4455,
      top: 205,
      width: 272,
      height: 400,
      style: GalleryFrameStyle.portrait,
      angle: 0,
    ),
    GalleryInstagramPlacement(
      id: 'instagram-5',
      postIndex: 5,
      left: 5970,
      top: 269,
      width: 400,
      height: 272,
      style: GalleryFrameStyle.horizontalOval,
      angle: 0,
    ),
    GalleryInstagramPlacement(
      id: 'instagram-6',
      postIndex: 6,
      left: 7295,
      top: 269,
      width: 272,
      height: 272,
      style: GalleryFrameStyle.circular,
      angle: 0,
    ),
  ];
}

double defaultGalleryStripWidthFor(String tripSlug) => switch (tripSlug) {
  'japan' => 9180,
  'south-korea' => 6800,
  _ => 6240,
};

GalleryDecorationPlacement defaultFoodMenuPlacementFor(String tripSlug) =>
    GalleryDecorationPlacement(
      id: 'food-menu',
      left: tripSlug == 'japan' ? 780 : 1838,
      top: 322,
      width: 250,
      height: 166,
    );

String formatGalleryTravelDate(DateTime date) {
  const months = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${months[date.month - 1]} '
      '${date.day.toString().padLeft(2, '0')}, ${date.year}';
}

String _dateOnlyIso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
