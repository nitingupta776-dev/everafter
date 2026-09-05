import 'dart:io';

import 'package:everafter/services/external_memory_scanner.dart';
import 'package:everafter/services/external_memory_scanner_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late ExternalMemoryScanner scanner;

  setUp(() {
    root = Directory.systemTemp.createTempSync('everafter-scanner-test-');
    scanner = createPlatformExternalMemoryScanner();
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  test('reports supported on a dart:io platform', () {
    expect(scanner.isSupported, isTrue);
  });

  test('missing folder scans to an empty list', () {
    final result = scanner.scan(
      rootPath: root.path,
      memoriesFolder: 'nowhere',
      tripName: 'Nowhere',
    );
    expect(result, isEmpty);
  });

  test('loose files directly in the trip folder become one named location', () {
    final tripDirectory = Directory('${root.path}/vegas')..createSync();
    File('${tripDirectory.path}/a.jpg').writeAsBytesSync(<int>[]);
    File('${tripDirectory.path}/b.png').writeAsBytesSync(<int>[]);
    File('${tripDirectory.path}/ignore.txt').writeAsBytesSync(<int>[]);

    final result = scanner.scan(
      rootPath: root.path,
      memoriesFolder: 'vegas',
      tripName: 'Las Vegas',
    );

    expect(result, hasLength(1));
    expect(result.single.label, 'Las Vegas');
    expect(result.single.assetPaths, hasLength(2));
    expect(
      result.single.assetPaths.every(
        (p) => p.endsWith('.jpg') || p.endsWith('.png'),
      ),
      isTrue,
    );
  });

  test('subfolders become separate, title-cased locations', () {
    final tripDirectory = Directory('${root.path}/japan')..createSync();
    final tokyo = Directory('${tripDirectory.path}/tokyo')..createSync();
    final kyoto = Directory('${tripDirectory.path}/kyoto_temples')
      ..createSync();
    File('${tokyo.path}/1.jpg').writeAsBytesSync(<int>[]);
    File('${tokyo.path}/2.jpg').writeAsBytesSync(<int>[]);
    File('${kyoto.path}/1.jpg').writeAsBytesSync(<int>[]);

    final result = scanner.scan(
      rootPath: root.path,
      memoriesFolder: 'japan',
      tripName: 'Japan',
    );

    final labels = result.map((l) => l.label).toSet();
    expect(labels, <String>{'Tokyo', 'Kyoto Temples'});
    final tokyoLocation = result.firstWhere((l) => l.label == 'Tokyo');
    expect(tokyoLocation.assetPaths, hasLength(2));
  });

  test('a video auto-pairs with a sibling -poster file', () {
    final tripDirectory = Directory('${root.path}/bali')..createSync();
    File('${tripDirectory.path}/reel-001.mp4').writeAsBytesSync(<int>[]);
    File('${tripDirectory.path}/reel-001-poster.jpg').writeAsBytesSync(<int>[]);
    File('${tripDirectory.path}/reel-002.mp4').writeAsBytesSync(<int>[]);

    final result = scanner.scan(
      rootPath: root.path,
      memoriesFolder: 'bali',
      tripName: 'Bali',
    );

    final location = result.single;
    final videoPath = location.assetPaths.firstWhere(
      (p) => p.endsWith('reel-001.mp4'),
    );
    final posterPath = location.assetPaths.firstWhere(
      (p) => p.endsWith('reel-001-poster.jpg'),
    );
    expect(location.videoPosterPaths[videoPath], posterPath);
    final unpaired = location.assetPaths.firstWhere(
      (p) => p.endsWith('reel-002.mp4'),
    );
    expect(location.videoPosterPaths.containsKey(unpaired), isFalse);
  });

  test('files are returned in alphabetical order', () {
    final tripDirectory = Directory('${root.path}/order')..createSync();
    for (final name in <String>['c.jpg', 'a.jpg', 'b.jpg']) {
      File('${tripDirectory.path}/$name').writeAsBytesSync(<int>[]);
    }

    final result = scanner.scan(
      rootPath: root.path,
      memoriesFolder: 'order',
      tripName: 'Order',
    );

    final names = result.single.assetPaths
        .map((p) => p.split(RegExp(r'[\\/]')).last)
        .toList();
    expect(names, <String>['a.jpg', 'b.jpg', 'c.jpg']);
  });
}
