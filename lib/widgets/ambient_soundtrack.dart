import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum EverAfterSoundEffect {
  tripCardZoom,
  globeEntrance,
  splashStart,
  paperBurn,
  frameSelect,
}

extension EverAfterSoundEffectAsset on EverAfterSoundEffect {
  String get assetPath => switch (this) {
    EverAfterSoundEffect.tripCardZoom => 'audio/trip-card-zoom.wav',
    EverAfterSoundEffect.globeEntrance => 'audio/globe-entrance-swell.wav',
    EverAfterSoundEffect.splashStart => 'audio/globe-entrance-swell.wav',
    EverAfterSoundEffect.paperBurn => 'audio/globe-entrance-swell.wav',
    EverAfterSoundEffect.frameSelect => 'audio/trip-card-zoom.wav',
  };

  String get mimeType => 'audio/wav';

  double get volumeMultiplier => switch (this) {
    EverAfterSoundEffect.tripCardZoom => 0.72,
    EverAfterSoundEffect.globeEntrance => 0.62,
    EverAfterSoundEffect.splashStart => 0.85,
    EverAfterSoundEffect.paperBurn => 0.5,
    EverAfterSoundEffect.frameSelect => 0.78,
  };

  Duration? get playbackDuration => switch (this) {
    // The crackle begins 220 ms after the Tap-to-enter cue, so 2.98 seconds
    // lands its final silent frame exactly on the 3.2-second paper transition.
    EverAfterSoundEffect.paperBurn => const Duration(milliseconds: 2980),
    _ => null,
  };

  double envelopeGainAt(Duration elapsed) {
    if (this != EverAfterSoundEffect.paperBurn) return 1;

    const fadeIn = Duration(milliseconds: 520);
    const fadeOutStart = Duration(milliseconds: 2080);
    const total = Duration(milliseconds: 2980);
    if (elapsed <= Duration.zero || elapsed >= total) return 0;
    if (elapsed < fadeIn) {
      return Curves.easeInOutSine.transform(
        elapsed.inMicroseconds / fadeIn.inMicroseconds,
      );
    }
    if (elapsed <= fadeOutStart) return 1;
    return 1 -
        Curves.easeInOutSine.transform(
          (elapsed - fadeOutStart).inMicroseconds /
              (total - fadeOutStart).inMicroseconds,
        );
  }
}

class EverAfterSoundEffects extends InheritedWidget {
  const EverAfterSoundEffects({
    required this.onPlay,
    this.onActivateAudio,
    required super.child,
    super.key,
  });

  final ValueChanged<EverAfterSoundEffect> onPlay;
  final VoidCallback? onActivateAudio;

  static void activateAudio(BuildContext context) {
    context
        .dependOnInheritedWidgetOfExactType<EverAfterSoundEffects>()
        ?.onActivateAudio
        ?.call();
  }

  static void play(BuildContext context, EverAfterSoundEffect effect) {
    context.dependOnInheritedWidgetOfExactType<EverAfterSoundEffects>()?.onPlay(
      effect,
    );
  }

  @override
  bool updateShouldNotify(EverAfterSoundEffects oldWidget) => false;
}

class AmbientSoundtrack extends StatefulWidget {
  const AmbientSoundtrack({
    required this.router,
    required this.child,
    super.key,
  });

  static const ambientSoundtrackAsset = 'audio/globe-entrance-swell.wav';
  static const chinaSoundtrackAsset = ambientSoundtrackAsset;
  static const japanSoundtrackAsset = ambientSoundtrackAsset;
  static const southKoreaSoundtrackAsset = ambientSoundtrackAsset;

  static String soundtrackAssetForPath(String path) {
    return switch (path) {
      '/trip/china' => chinaSoundtrackAsset,
      '/trip/japan' => japanSoundtrackAsset,
      '/trip/south-korea' => southKoreaSoundtrackAsset,
      _ => ambientSoundtrackAsset,
    };
  }

  final GoRouter router;
  final Widget child;

  @override
  State<AmbientSoundtrack> createState() => _AmbientSoundtrackState();
}

class _AmbientSoundtrackState extends State<AmbientSoundtrack> {
  static const _initialVolume = 0.35;

  late final AudioPlayer _player = AudioPlayer(
    playerId: 'everafter-ambient-soundtrack',
  );
  late final AudioPlayer _effectsPlayer = AudioPlayer(
    playerId: 'everafter-sound-effects',
  );
  late final StreamSubscription<PlayerState> _playerStateSubscription;

  double _volume = _initialVolume;
  bool _isMuted = kIsWeb;
  // Browser ambience starts silently to respect autoplay policy. Interaction
  // effects are user-gesture driven, so they remain available until the user
  // explicitly mutes the shared audio controls.
  bool _effectsMuted = false;
  bool _isPlaying = false;
  bool _isPreparing = false;
  bool _controlsOpen = false;
  EverAfterSoundEffect? _activeEffect;
  int _effectPlaybackId = 0;
  late String _activeRoutePath;
  late String _activeSoundtrackAsset;
  String? _preparedSoundtrackAsset;

  @override
  void initState() {
    super.initState();
    _activeRoutePath = _currentRoutePath();
    _activeSoundtrackAsset = AmbientSoundtrack.soundtrackAssetForPath(
      _activeRoutePath,
    );
    widget.router.routerDelegate.addListener(_handleRouteChange);
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareAndAutoplay());
    });
  }

  @override
  void didUpdateWidget(covariant AmbientSoundtrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router == widget.router) return;

    oldWidget.router.routerDelegate.removeListener(_handleRouteChange);
    widget.router.routerDelegate.addListener(_handleRouteChange);
    _handleRouteChange();
  }

  String _currentRoutePath() {
    final delegate = widget.router.routerDelegate;
    return delegate.currentConfiguration.isEmpty
        ? widget.router.routeInformationProvider.value.uri.path
        : delegate.state.uri.path;
  }

  void _handleRouteChange() {
    final routePath = _currentRoutePath();
    final soundtrackAsset = AmbientSoundtrack.soundtrackAssetForPath(routePath);
    if (routePath == _activeRoutePath &&
        soundtrackAsset == _activeSoundtrackAsset) {
      return;
    }

    final soundtrackChanged = soundtrackAsset != _activeSoundtrackAsset;
    setState(() {
      _activeRoutePath = routePath;
      _activeSoundtrackAsset = soundtrackAsset;
    });
    if (soundtrackChanged) unawaited(_switchToActiveSoundtrack());
  }

  Future<void> _switchToActiveSoundtrack() async {
    final targetAsset = _activeSoundtrackAsset;
    final shouldResume = _isPlaying;

    try {
      await _player.stop();
    } on Exception catch (error) {
      debugPrint(
        'EverAfter soundtrack could not stop before switching: $error',
      );
    }
    if (!mounted || targetAsset != _activeSoundtrackAsset) return;

    setState(() => _isPlaying = false);
    _preparedSoundtrackAsset = null;
    if (!await _prepareSource() ||
        !mounted ||
        targetAsset != _activeSoundtrackAsset ||
        !shouldResume) {
      return;
    }

    try {
      await _player.resume();
      if (mounted) setState(() => _isPlaying = true);
    } on Exception catch (error) {
      debugPrint(
        'EverAfter soundtrack could not resume after switching: $error',
      );
    }
  }

  Future<void> _prepareAndAutoplay() async {
    if (!await _prepareSource()) return;

    try {
      await _player.resume();
      if (mounted) setState(() => _isPlaying = true);
    } on Exception catch (error) {
      // Audible browser autoplay is commonly blocked. The source remains
      // prepared so the explicit unmute control can resume it immediately.
      debugPrint('EverAfter soundtrack autoplay was blocked: $error');
    }
  }

  Future<bool> _prepareSource() async {
    final targetAsset = _activeSoundtrackAsset;
    if (_preparedSoundtrackAsset == targetAsset) return true;
    if (_isPreparing) {
      while (_isPreparing && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return _prepareSource();
    }

    _isPreparing = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_isMuted ? 0 : _volume);
      await _player.setSource(AssetSource(targetAsset, mimeType: 'audio/wav'));
      _preparedSoundtrackAsset = targetAsset;
      return targetAsset == _activeSoundtrackAsset;
    } on Exception catch (error) {
      debugPrint('EverAfter soundtrack could not be prepared: $error');
      return false;
    } finally {
      _isPreparing = false;
    }
  }

  void _toggleControls() {
    setState(() => _controlsOpen = !_controlsOpen);
  }

  void _requestSoundEffect(EverAfterSoundEffect effect) {
    unawaited(_playSoundEffect(effect));
  }

  void _activateAudioFromInteraction() {
    if (_isMuted || _effectsMuted) {
      setState(() {
        _isMuted = false;
        _effectsMuted = false;
      });
    }
    unawaited(_activateAudioPlayback());
  }

  Future<void> _activateAudioPlayback() async {
    if (_isPlaying) {
      try {
        await _player.setVolume(_volume);
      } on Exception catch (error) {
        debugPrint('EverAfter soundtrack could not be unmuted: $error');
      }
      return;
    }

    await _resumeFromControl();
  }

  Future<void> _playSoundEffect(EverAfterSoundEffect effect) async {
    if (_effectsMuted || _volume == 0) return;

    final playbackId = ++_effectPlaybackId;
    _activeEffect = effect;
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.setReleaseMode(ReleaseMode.stop);
      await _effectsPlayer.setVolume(
        _volume *
            effect.volumeMultiplier *
            effect.envelopeGainAt(Duration.zero),
      );
      await _effectsPlayer.play(
        AssetSource(effect.assetPath, mimeType: effect.mimeType),
      );
      if (effect.playbackDuration != null) {
        unawaited(_runSoundEffectEnvelope(effect, playbackId));
      }
    } on Exception catch (error) {
      debugPrint('EverAfter sound effect could not play: $error');
    }
  }

  Future<void> _runSoundEffectEnvelope(
    EverAfterSoundEffect effect,
    int playbackId,
  ) async {
    final duration = effect.playbackDuration;
    if (duration == null) return;

    final stopwatch = Stopwatch()..start();
    while (mounted &&
        playbackId == _effectPlaybackId &&
        stopwatch.elapsed < duration) {
      final gain = effect.envelopeGainAt(stopwatch.elapsed);
      try {
        await _effectsPlayer.setVolume(
          _effectsMuted ? 0 : _volume * effect.volumeMultiplier * gain,
        );
      } on Exception catch (error) {
        debugPrint('EverAfter sound effect fade could not update: $error');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (playbackId != _effectPlaybackId) return;
    try {
      await _effectsPlayer.setVolume(0);
      await _effectsPlayer.stop();
      _activeEffect = null;
    } on Exception catch (error) {
      debugPrint('EverAfter sound effect could not finish: $error');
    }
  }

  Future<void> _toggleMuted() async {
    if (!_isPlaying || _isMuted) {
      setState(() {
        _isMuted = false;
        _effectsMuted = false;
      });
      await _resumeFromControl();
      return;
    }

    setState(() {
      _isMuted = true;
      _effectsMuted = true;
    });
    try {
      await Future.wait(<Future<void>>[
        _player.setVolume(0),
        _effectsPlayer.setVolume(0),
      ]);
    } on Exception catch (error) {
      debugPrint('EverAfter audio could not be muted: $error');
    }
  }

  void _changeVolume(double volume) {
    setState(() {
      _volume = volume;
      _isMuted = volume == 0;
      _effectsMuted = volume == 0;
    });
    unawaited(_applyVolumeFromControl(volume));
  }

  Future<void> _applyVolumeFromControl(double volume) async {
    if (volume > 0 && !_isPlaying) {
      await _resumeFromControl();
      return;
    }

    try {
      await _player.setVolume(volume);
      final effect = _activeEffect;
      if (effect != null) {
        await _effectsPlayer.setVolume(volume * effect.volumeMultiplier);
      }
    } on Exception catch (error) {
      debugPrint('EverAfter audio volume could not be changed: $error');
    }
  }

  Future<void> _resumeFromControl() async {
    if (_preparedSoundtrackAsset != _activeSoundtrackAsset &&
        !await _prepareSource()) {
      return;
    }

    try {
      // Resume first while the browser still considers this a user gesture,
      // then raise the gain from the muted autoplay value.
      await _player.resume();
      await _player.setVolume(_volume);
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isMuted = false;
        });
      }
    } on Exception catch (error) {
      debugPrint('EverAfter soundtrack could not start: $error');
    }
  }

  @override
  void dispose() {
    _effectPlaybackId++;
    widget.router.routerDelegate.removeListener(_handleRouteChange);
    unawaited(_playerStateSubscription.cancel());
    unawaited(_player.dispose());
    unawaited(_effectsPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soundtrackKey = switch (_activeRoutePath) {
      '/trip/china' => 'active-soundtrack-china',
      '/trip/japan' => 'active-soundtrack-japan',
      '/trip/south-korea' => 'active-soundtrack-south-korea',
      _ => 'active-soundtrack-ambient',
    };
    return EverAfterSoundEffects(
      onPlay: _requestSoundEffect,
      onActivateAudio: _activateAudioFromInteraction,
      child: Stack(
        key: ValueKey(soundtrackKey),
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          Positioned(
            left: 22,
            bottom: 20,
            child: RepaintBoundary(
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      reverseDuration: const Duration(milliseconds: 140),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.bottomLeft,
                          child: child,
                        ),
                      ),
                      child: _controlsOpen
                          ? Padding(
                              key: const ValueKey('soundtrack-controls-open'),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SoundtrackControls(
                                isMuted: _isMuted,
                                isPlaying: _isPlaying,
                                volume: _volume,
                                onToggleMuted: _toggleMuted,
                                onVolumeChanged: _changeVolume,
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('soundtrack-controls-closed'),
                            ),
                    ),
                    Semantics(
                      button: true,
                      toggled: _controlsOpen,
                      label: _controlsOpen
                          ? 'Close soundtrack controls'
                          : 'Open soundtrack controls',
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: EverAfterColors.ink.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          key: const ValueKey('soundtrack-button'),
                          color: EverAfterColors.ink,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _toggleControls,
                            child: const SizedBox.square(
                              dimension: 56,
                              child: Icon(
                                Icons.music_note_rounded,
                                color: EverAfterColors.paper,
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundtrackControls extends StatelessWidget {
  const _SoundtrackControls({
    required this.isMuted,
    required this.isPlaying,
    required this.volume,
    required this.onToggleMuted,
    required this.onVolumeChanged,
  });

  final bool isMuted;
  final bool isPlaying;
  final double volume;
  final VoidCallback onToggleMuted;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    final needsSound = isMuted || !isPlaying;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: EverAfterColors.ink.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        key: const ValueKey('soundtrack-controls'),
        color: EverAfterColors.paper.withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: EverAfterColors.ink.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 56,
          height: 188,
          child: Column(
            children: <Widget>[
              Semantics(
                button: true,
                label: needsSound ? 'Unmute soundtrack' : 'Mute soundtrack',
                child: IconButton(
                  key: const ValueKey('soundtrack-mute-toggle'),
                  onPressed: onToggleMuted,
                  color: EverAfterColors.ink,
                  icon: Icon(
                    needsSound
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 22,
                  ),
                ),
              ),
              Expanded(
                child: _VerticalVolumeSlider(
                  key: const ValueKey('soundtrack-volume'),
                  value: volume,
                  onChanged: onVolumeChanged,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalVolumeSlider extends StatelessWidget {
  const _VerticalVolumeSlider({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    void adjust(double delta) => onChanged((value + delta).clamp(0.0, 1.0));

    return Semantics(
      label: 'Soundtrack volume',
      value: '${(value * 100).round()} percent',
      increasedValue:
          '${((value + 0.1).clamp(0.0, 1.0) * 100).round()} percent',
      decreasedValue:
          '${((value - 0.1).clamp(0.0, 1.0) * 100).round()} percent',
      onIncrease: () => adjust(0.1),
      onDecrease: () => adjust(-0.1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: LayoutBuilder(
          builder: (context, constraints) {
            void updateFrom(double dy) {
              onChanged((1 - (dy / constraints.maxHeight)).clamp(0.0, 1.0));
            }

            const thumbSize = 14.0;
            final thumbTop = (constraints.maxHeight - thumbSize) * (1 - value);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => updateFrom(details.localPosition.dy),
              onVerticalDragUpdate: (details) =>
                  updateFrom(details.localPosition.dy),
              child: SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(width: 2, color: EverAfterColors.catalogLine),
                    Positioned(
                      top: constraints.maxHeight * (1 - value),
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: EverAfterColors.warmBrown,
                      ),
                    ),
                    Positioned(
                      top: thumbTop,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: EverAfterColors.burgundy,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(dimension: thumbSize),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
