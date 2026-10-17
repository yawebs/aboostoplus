import 'dart:io';

import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/videos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../widgets/video_playback_manager.dart';

class VideoDisplayWidget extends StatefulWidget {
  final PropertyModel property;

  const VideoDisplayWidget({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<VideoDisplayWidget> createState() => _VideoDisplayWidgetState();
}

class _VideoDisplayWidgetState extends State<VideoDisplayWidget> {
  VideoPlayerController? _controller;

  final VideoPlaybackManager _manager = VideoPlaybackManager.instance;

  bool soundEnabled = false;
  bool _initializing = true;
  bool _disposed = false;

  final Key _visibilityKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    final images = widget.property.images;

    if (images.isEmpty || images.first.isEmpty) {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
      return;
    }

    final String url = images.first;

    debugPrint(
      'VideoDisplayWidget loading: $url',
    );

    VideoPlayerController? controller;

    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      await controller.initialize();

      if (_disposed) {
        await controller.dispose();
        return;
      }

      controller.setVolume(0.0);
      controller.setLooping(true);

      _controller = controller;

      // _manager.;

      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    } on PlatformException catch (e) {
      debugPrint(
        'Home video PlatformException: $e',
      );

      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    } on SocketException catch (e) {
      debugPrint(
        'Home video SocketException: $e',
      );

      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Home video initialization error: $e',
      );

      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  void _playVideo() {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.hasError ||
        _disposed) {
      return;
    }

    _manager.play(controller);
  }

  void _pauseVideo() {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    _manager.pause(controller);
  }

  void _toggleSound() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized || _disposed) {
      return;
    }

    soundEnabled = !soundEnabled;

    controller.setVolume(
      soundEnabled ? 1.0 : 0.0,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _openVideosScreen() {
    // IMPORTANT:
    //
    // Stop this home-screen video before navigating.
    // This guarantees that it cannot continue playing
    // underneath VideosScreen.
    _pauseVideo();

    goTo(
      context,
      VideosScreen(
        clickedVideo: widget.property,
      ),
      false,
    );
  }

  @override
  void dispose() {
    _disposed = true;

    final controller = _controller;

    if (controller != null) {
      _manager.unregister(controller);

      _controller = null;

      try {
        controller.dispose();
      } catch (_) {}
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return ClipRRect(
        borderRadius: appRadius(10.0),
        child: Container(
          width: width(context),
          height: 300,
          decoration: BoxDecoration(
            borderRadius: appRadius(10.0),
            color: black,
          ),
          margin: const EdgeInsets.only(
            bottom: 8.0,
          ),
          child: Center(
            child: videoLoader(size: 40),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: appRadius(10.0),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio / 0.7,
        child: Container(
          width: width(context),
          decoration: BoxDecoration(
            borderRadius: appRadius(10.0),
            color: black,
          ),
          margin: const EdgeInsets.only(
            bottom: 8.0,
          ),
          child: VisibilityDetector(
            key: _visibilityKey,
            onVisibilityChanged: (info) {
              final visiblePercentage = info.visibleFraction * 100;

              if (visiblePercentage > 50.0) {
                _playVideo();
              } else {
                _pauseVideo();
              }
            },
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: _openVideosScreen,
                    child: VideoPlayer(controller),
                  ),
                  Positioned(
                    top: 10,
                    left: 5,
                    child: GestureDetector(
                      onTap: _toggleSound,
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircleAvatar(
                          backgroundColor: black.withOpacity(.5),
                          child: Icon(
                            soundEnabled ? Icons.volume_up : Icons.volume_mute,
                            color: white,
                            size: 12,
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
      ),
    );
  }
}
