class JapanInstagramPost {
  const JapanInstagramPost({
    required this.shortcode,
    required this.permalink,
    required this.coverAssetPath,
    required this.videoAssetPath,
  });

  final String shortcode;
  final String permalink;
  final String coverAssetPath;
  final String videoAssetPath;
}

const _demoVideoAsset = 'assets/video/public-demo-memory.mp4';

const List<JapanInstagramPost> japanInstagramPosts = <JapanInstagramPost>[
  JapanInstagramPost(
    shortcode: 'demo-01',
    permalink: '',
    coverAssetPath: 'assets/images/experience/earth-globe-fallback.png',
    videoAssetPath: _demoVideoAsset,
  ),
  JapanInstagramPost(
    shortcode: 'demo-02',
    permalink: '',
    coverAssetPath:
        'assets/images/experience/earth-globe-japan-centered-rotation-sheet.jpg',
    videoAssetPath: _demoVideoAsset,
  ),
  JapanInstagramPost(
    shortcode: 'demo-03',
    permalink: '',
    coverAssetPath:
        'assets/images/experience/earth-globe-south-korea-centered-rotation-sheet.jpg',
    videoAssetPath: _demoVideoAsset,
  ),
  JapanInstagramPost(
    shortcode: 'demo-04',
    permalink: '',
    coverAssetPath:
        'assets/images/experience/earth-globe-china-centered-rotation-sheet.jpg',
    videoAssetPath: _demoVideoAsset,
  ),
  JapanInstagramPost(
    shortcode: 'demo-05',
    permalink: '',
    coverAssetPath:
        'assets/images/experience/earth-globe-hong-kong-centered-rotation-sheet.jpg',
    videoAssetPath: _demoVideoAsset,
  ),
  JapanInstagramPost(
    shortcode: 'demo-06',
    permalink: '',
    coverAssetPath:
        'assets/images/experience/earth-globe-taiwan-centered-rotation-sheet.jpg',
    videoAssetPath: _demoVideoAsset,
  ),
  JapanInstagramPost(
    shortcode: 'demo-07',
    permalink: '',
    coverAssetPath:
        'assets/images/experience/earth-globe-bali-centered-rotation-sheet.jpg',
    videoAssetPath: _demoVideoAsset,
  ),
];
