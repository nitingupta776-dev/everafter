import 'package:everafter/app.dart';
import 'package:everafter/data/gallery_layout.dart';
import 'package:everafter/data/trip_catalog_store.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Future.wait(<Future<void>>[
    GalleryLayoutStore.instance.load(),
    TripCatalogStore.instance.load(),
  ]);
  debugPaintBaselinesEnabled = false;
  runApp(const ProviderScope(child: EverAfterApp()));
}
