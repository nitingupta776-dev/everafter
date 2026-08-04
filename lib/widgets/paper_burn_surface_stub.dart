import 'package:flutter/widgets.dart';

const bool paperBurnUsesWebGL = false;

class PaperBurnWebGLSurface extends StatelessWidget {
  const PaperBurnWebGLSurface({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
