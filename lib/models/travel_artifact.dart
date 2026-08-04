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
}

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
}
