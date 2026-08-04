/// Public-safe assets used by the repository's demo data.
///
/// Personal photos and videos live in ignored local directories. Keeping the
/// public demo on a known, redistributable image means a fresh clone can build
/// and run without bundling anyone's travel archive.
const publicMemoryPlaceholderAsset =
    'assets/images/experience/earth-globe-fallback.png';

const publicDemoMemoryAssets = <String>[
  publicMemoryPlaceholderAsset,
  'assets/images/experience/earth-globe-japan-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-south-korea-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-china-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-hong-kong-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-taiwan-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-bali-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-thailand-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-malaysia-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-philippines-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-vietnam-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-sri-lanka-centered-rotation-sheet.jpg',
  'assets/images/experience/earth-globe-turkey-centered-rotation-sheet.jpg',
];

List<String> publicMemoryPlaceholders(int count) => List<String>.generate(
  count,
  (index) => publicDemoMemoryAssets[index % publicDemoMemoryAssets.length],
  growable: false,
);
