import 'package:everafter/theme/everafter_theme.dart';
import 'package:flutter/material.dart';

class ExhibitChapter {
  const ExhibitChapter({
    required this.kicker,
    required this.title,
    required this.body,
    required this.detail,
  });

  final String kicker;
  final String title;
  final String body;
  final String detail;

  Map<String, Object?> toJson() => <String, Object?>{
    'kicker': kicker,
    'title': title,
    'body': body,
    'detail': detail,
  };

  factory ExhibitChapter.fromJson(Map<String, dynamic> json) {
    return ExhibitChapter(
      kicker: json['kicker'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      detail: json['detail'] as String,
    );
  }
}

/// Named palette colors an artifact can reference from JSON, since the
/// underlying [Color] values live as Dart consts in [EverAfterColors].
const artifactColorPalette = <String, Color>{
  'burgundy': EverAfterColors.burgundy,
  'brass': EverAfterColors.brass,
  'olive': EverAfterColors.olive,
  'warmBrown': EverAfterColors.warmBrown,
  'ink': EverAfterColors.ink,
  'agedPaper': EverAfterColors.agedPaper,
};

String artifactColorName(Color color) => artifactColorPalette.entries
    .firstWhere(
      (entry) => entry.value.toARGB32() == color.toARGB32(),
      orElse: () =>
          const MapEntry<String, Color>('brass', EverAfterColors.brass),
    )
    .key;

class TravelArtifact {
  const TravelArtifact({
    required this.uid,
    required this.title,
    required this.place,
    required this.country,
    required this.dateLabel,
    required this.coordinates,
    required this.medium,
    required this.collection,
    required this.accessionNumber,
    required this.coverLine,
    required this.modelAsset,
    required this.colors,
    required this.chapters,
  });

  final String uid;
  final String title;
  final String place;
  final String country;
  final String dateLabel;
  final String coordinates;
  final String medium;
  final String collection;
  final String accessionNumber;
  final String coverLine;
  final String modelAsset;
  final List<Color> colors;
  final List<ExhibitChapter> chapters;

  Map<String, Object?> toJson() => <String, Object?>{
    'uid': uid,
    'title': title,
    'place': place,
    'country': country,
    'dateLabel': dateLabel,
    'coordinates': coordinates,
    'medium': medium,
    'collection': collection,
    'accessionNumber': accessionNumber,
    'coverLine': coverLine,
    'modelAsset': modelAsset,
    'colors': <String>[for (final color in colors) artifactColorName(color)],
    'chapters': <Object?>[for (final chapter in chapters) chapter.toJson()],
  };

  factory TravelArtifact.fromJson(Map<String, dynamic> json) {
    return TravelArtifact(
      uid: json['uid'] as String,
      title: json['title'] as String,
      place: json['place'] as String,
      country: json['country'] as String,
      dateLabel: json['dateLabel'] as String,
      coordinates: json['coordinates'] as String,
      medium: json['medium'] as String,
      collection: json['collection'] as String,
      accessionNumber: json['accessionNumber'] as String,
      coverLine: json['coverLine'] as String,
      modelAsset: json['modelAsset'] as String,
      colors: <Color>[
        for (final name in (json['colors'] as List<dynamic>).cast<String>())
          artifactColorPalette[name] ?? EverAfterColors.brass,
      ],
      chapters: <ExhibitChapter>[
        for (final chapter in (json['chapters'] as List<dynamic>))
          ExhibitChapter.fromJson(chapter as Map<String, dynamic>),
      ],
    );
  }
}
