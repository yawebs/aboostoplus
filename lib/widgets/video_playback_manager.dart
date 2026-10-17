import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoPlaybackManager {
  VideoPlaybackManager._();

  static final VideoPlaybackManager instance = VideoPlaybackManager._();

  VideoPlayerController? _activeController;

  final Set<VideoPlayerController> _controllers = <VideoPlayerController>{};

  bool _isSwitching = false;

  // ===========================================================================
  // REGISTER
  // ===========================================================================

  void register(VideoPlayerController controller) {
    _controllers.add(controller);

    debugPrint(
      '[VideoManager] Registered controller. '
      'Total: ${_controllers.length}',
    );
  }

  // ===========================================================================
  // UNREGISTER
  // ===========================================================================

  void unregister(VideoPlayerController controller) {
    _controllers.remove(controller);

    if (identical(_activeController, controller)) {
      _activeController = null;
    }

    debugPrint(
      '[VideoManager] Unregistered controller. '
      'Total: ${_controllers.length}',
    );
  }

  // ===========================================================================
  // PLAY
  // ===========================================================================

  Future<void> play(VideoPlayerController controller) async {
    if (!controller.value.isInitialized || controller.value.hasError) {
      return;
    }

    // Prevent multiple simultaneous switch operations.
    if (_isSwitching) {
      return;
    }

    _isSwitching = true;

    try {
      // -----------------------------------------------------------------------
      // If another video is playing, STOP IT FIRST.
      // -----------------------------------------------------------------------

      final previous = _activeController;

      if (previous != null && !identical(previous, controller)) {
        try {
          await previous.pause();
        } catch (_) {}

        debugPrint(
          '[VideoManager] Previous video paused.',
        );
      }

      // -----------------------------------------------------------------------
      // Make this the active controller.
      // -----------------------------------------------------------------------

      _activeController = controller;

      // -----------------------------------------------------------------------
      // Make sure every other registered controller is paused.
      // -----------------------------------------------------------------------

      for (final other in _controllers) {
        if (identical(other, controller)) {
          continue;
        }

        try {
          if (other.value.isPlaying) {
            await other.pause();
          }
        } catch (_) {}
      }

      // -----------------------------------------------------------------------
      // Start only this controller.
      // -----------------------------------------------------------------------

      if (!controller.value.isPlaying) {
        await controller.play();
      }

      debugPrint(
        '[VideoManager] Playing active video.',
      );
    } catch (e) {
      debugPrint(
        '[VideoManager] Play error: $e',
      );
    } finally {
      _isSwitching = false;
    }
  }

  // ===========================================================================
  // PAUSE
  // ===========================================================================

  Future<void> pause(VideoPlayerController controller) async {
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      }

      if (identical(_activeController, controller)) {
        _activeController = null;
      }
    } catch (e) {
      debugPrint(
        '[VideoManager] Pause error: $e',
      );
    }
  }

  // ===========================================================================
  // PAUSE EVERYTHING
  // ===========================================================================

  Future<void> pauseAll() async {
    for (final controller in List<VideoPlayerController>.from(_controllers)) {
      try {
        if (controller.value.isPlaying) {
          await controller.pause();
        }
      } catch (_) {}
    }

    _activeController = null;
  }

  // ===========================================================================
  // ACTIVE CONTROLLER
  // ===========================================================================

  VideoPlayerController? get activeController => _activeController;

  // ===========================================================================
  // DISPOSE ALL
  // ===========================================================================

  Future<void> disposeAll() async {
    final controllers = List<VideoPlayerController>.from(_controllers);

    _controllers.clear();
    _activeController = null;

    for (final controller in controllers) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }
}
