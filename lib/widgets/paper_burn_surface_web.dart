import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

@JS('everafterPaperBurnSupported')
external bool _paperBurnSupported();

@JS('everafterPaperBurnMount')
external void _mountPaperBurn(web.HTMLCanvasElement canvas, JSString id);

@JS('everafterPaperBurnSetProgress')
external void _setPaperBurnProgress(JSString id, double progress);

@JS('everafterPaperBurnDispose')
external void _disposePaperBurn(JSString id);

bool get paperBurnUsesWebGL => _paperBurnSupported();

class PaperBurnWebGLSurface extends StatefulWidget {
  const PaperBurnWebGLSurface({required this.progress, super.key});

  final double progress;

  @override
  State<PaperBurnWebGLSurface> createState() => _PaperBurnWebGLSurfaceState();
}

class _PaperBurnWebGLSurfaceState extends State<PaperBurnWebGLSurface> {
  static int _nextId = 0;

  late final String _instanceId;
  late final String _viewType;
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _instanceId = 'everafter-paper-burn-${_nextId++}';
    _viewType = '$_instanceId-view';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      final canvas = web.HTMLCanvasElement()
        ..id = _instanceId
        ..ariaLabel = 'Animated paper burn edge';
      canvas.style
        ..width = '100%'
        ..height = '100%'
        ..display = 'block'
        ..pointerEvents = 'none'
        ..background = 'transparent';
      _mountPaperBurn(canvas, _instanceId.toJS);
      _mounted = true;
      _updateProgress();
      return canvas;
    });
  }

  @override
  void didUpdateWidget(PaperBurnWebGLSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    if (!_mounted) return;
    _setPaperBurnProgress(_instanceId.toJS, widget.progress.clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    if (_mounted) {
      _disposePaperBurn(_instanceId.toJS);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: const ValueKey('paper-burn-webgl-surface'),
      viewType: _viewType,
    );
  }
}
