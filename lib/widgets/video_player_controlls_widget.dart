import 'dart:async';
import 'dart:io';

import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'video_playback_manager.dart';

class VideoWidgetPlayerControllsWidget extends StatefulWidget {
  final PropertyModel property;

  /// True when this video is the currently visible PageView page.
  final bool isActive;

  /// Called when user taps the video.
  final VoidCallback? onVideoTap;

  const VideoWidgetPlayerControllsWidget({
    Key? key,
    required this.property,
    required this.isActive,
    this.onVideoTap,
  }) : super(key: key);

  @override
  State<VideoWidgetPlayerControllsWidget> createState() =>
      _VideoWidgetPlayerControllsWidgetState();
}

class _VideoWidgetPlayerControllsWidgetState
    extends State<VideoWidgetPlayerControllsWidget>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;

  final VideoPlaybackManager _manager = VideoPlaybackManager.instance;

  bool _initializing = false;
  bool _disposed = false;
  bool _userPaused = false;
  // Sound is on by default. Shared across every video in the feed, so muting
  // one keeps the next ones muted (and unmuting brings sound back for all)
  // instead of each page resetting on swipe.
  static bool _soundEnabled = true;

  int _initializationGeneration = 0;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();

    if (widget.isActive) {
      _initialize();
    }
  }

  @override
  void didUpdateWidget(
    covariant VideoWidgetPlayerControllsWidget oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _activate();
      } else {
        _deactivate();
      }
    }
  }

  // ===========================================================================
  // INITIALIZE
  // ===========================================================================

  Future<void> _initialize() async {
    if (_disposed || _controller != null || _initializing) {
      return;
    }

    final images = widget.property.images;

    if (images.isEmpty) {
      return;
    }

    final url = images.first.trim();

    if (url.isEmpty) {
      return;
    }

    _initializing = true;

    final int generation = ++_initializationGeneration;

    if (mounted) {
      setState(() {});
    }

    debugPrint(
      '[VideoWidget] Initializing: $url',
    );

    VideoPlayerController? controller;

    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      await controller.initialize();

      // -----------------------------------------------------------------------
      // The widget may have been disposed while the video was loading.
      // -----------------------------------------------------------------------

      if (_disposed || generation != _initializationGeneration) {
        try {
          await controller.dispose();
        } catch (_) {}

        return;
      }

      controller.setLooping(true);
      controller.setVolume(
        _soundEnabled ? 1.0 : 0.0,
      );

      _controller = controller;

      _manager.register(controller);

      _initializing = false;

      if (mounted) {
        setState(() {});
      }

      // -----------------------------------------------------------------------
      // Start only if this is still the active page.
      // -----------------------------------------------------------------------

      if (widget.isActive && !_userPaused) {
        await _manager.play(controller);
      }
    } on PlatformException catch (e) {
      debugPrint(
        '[VideoWidget] PlatformException: $e',
      );

      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }

      _initializing = false;

      if (mounted) {
        setState(() {});
      }
    } on SocketException catch (e) {
      debugPrint(
        '[VideoWidget] SocketException: $e',
      );

      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }

      _initializing = false;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        '[VideoWidget] Initialization error: $e',
      );

      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }

      _initializing = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  // ===========================================================================
  // ACTIVATE
  // ===========================================================================

  Future<void> _activate() async {
    _userPaused = false;

    if (_controller == null) {
      await _initialize();
      return;
    }

    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.hasError) {
      return;
    }

    // Kept-alive pages may have been built before the mute setting last
    // changed, so re-apply it whenever a page becomes the active one.
    await controller.setVolume(_soundEnabled ? 1.0 : 0.0);
    await _manager.play(controller);

    if (mounted) {
      setState(() {});
    }
  }

  // ===========================================================================
  // DEACTIVATE
  // ===========================================================================

  Future<void> _deactivate() async {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    try {
      await _manager.pause(controller);
    } catch (_) {}

    // -------------------------------------------------------------------------
    // IMPORTANT:
    //
    // We release the controller when this page is no longer active.
    //
    // This is what keeps a long TikTok-style feed from accumulating many
    // ExoPlayer instances and eventually hitting the Android heap limit.
    // -------------------------------------------------------------------------

    await _releaseController();
  }

  // ===========================================================================
  // RELEASE CONTROLLER
  // ===========================================================================

  Future<void> _releaseController() async {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    _controller = null;

    _manager.unregister(controller);

    try {
      await controller.pause();
    } catch (_) {}

    try {
      await controller.dispose();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  // ===========================================================================
  // TOGGLE PLAYBACK
  // ===========================================================================

  Future<void> _togglePlayback() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.hasError) {
      return;
    }

    if (controller.value.isPlaying) {
      _userPaused = true;

      await _manager.pause(controller);
    } else {
      _userPaused = false;

      await _manager.play(controller);
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ===========================================================================
  // TOGGLE SOUND
  // ===========================================================================

  void _toggleSound() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _soundEnabled = !_soundEnabled;

    controller.setVolume(
      _soundEnabled ? 1.0 : 0.0,
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _disposed = true;

    _initializationGeneration++;

    final controller = _controller;

    if (controller != null) {
      _manager.unregister(controller);

      try {
        controller.dispose();
      } catch (_) {}
    }

    _controller = null;

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final controller = _controller;

    // -------------------------------------------------------------------------
    // LOADING / NOT ACTIVE
    // -------------------------------------------------------------------------

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child:
            _initializing ? videoLoader(size: 38) : const SizedBox.shrink(),
      );
    }

    // -------------------------------------------------------------------------
    // VIDEO
    // -------------------------------------------------------------------------

    return Container(
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.onVideoTap != null) {
            widget.onVideoTap!();
          } else {
            _togglePlayback();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ================================================================
            // VIDEO
            // ================================================================

            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),

            // ================================================================
            // DARK GRADIENT AT BOTTOM
            // ================================================================

            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 230,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(.78),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ================================================================
            // PLAY ICON
            // ================================================================

            if (!controller.value.isPlaying)
              Center(
                child: IgnorePointer(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // ================================================================
            // SOUND BUTTON
            // ================================================================

            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              right: 15,
              child: GestureDetector(
                onTap: _toggleSound,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _soundEnabled ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
