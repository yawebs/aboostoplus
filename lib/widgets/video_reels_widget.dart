import 'dart:io';

import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/videos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoReelsWidget extends StatefulWidget {
  final PropertyModel property;
  final int index;
  const VideoReelsWidget(
      {Key? key, required this.property, required this.index})
      : super(key: key);

  @override
  State<VideoReelsWidget> createState() => _VideoReelsWidgetState();
}

class _VideoReelsWidgetState extends State<VideoReelsWidget> {
  late VideoPlayerController _controller;
  ScrollController scrollController = ScrollController();
  bool soundEnabled = false;
  bool userPaused = false;
  Key _key = UniqueKey();
  initializeVideoPlayer() async {
    try {
      if (widget.property.images.first != null) {
        setState(() {
          _controller = VideoPlayerController.networkUrl(
              Uri.parse(widget.property.images.first))
            ..initialize().then((_) {
              // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
              setState(() {
                _controller.setVolume(0.0);
                // _controller.play();
              });
            });
        });
      }
    } on PlatformException catch (_) {
      // setState(() {
      //   _controller = VideoPlayerController.networkUrl(
      //       Uri.parse(widget.property.images.first))
      //     ..initialize().then((_) {
      //       // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
      //       setState(() {
      //         _controller.setVolume(0.0);
      //         _controller.play();
      //       });
      //     });
      // });
    } on SocketException catch (_) {
      // setState(() {
      //   _controller = VideoPlayerController.networkUrl(
      //       Uri.parse(widget.property.images.first))
      //     ..initialize().then((_) {
      //       // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
      //       setState(() {
      //         _controller.setVolume(0.0);
      //         _controller.play();
      //       });
      //     });
      // });
    } catch (e) {
      // _controller = VideoPlayerController.networkUrl(
      //     Uri.parse(widget.property.images.first))
      //   ..initialize().then((_) {
      //     // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
      //     setState(() {
      //       _controller.setVolume(0.0);
      //       // _controller.play();
      //     });
      //   });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: appRadius(15.0),
        child: Container(
          width: 200,
          decoration:
              BoxDecoration(borderRadius: appRadius(10.0), color: black),
          child: VisibilityDetector(
            key: _key,
            onVisibilityChanged: (info) {
              var visiblePercentage = info.visibleFraction * 100;

              if (visiblePercentage == 100.0) {
                if (userPaused == false) {
                  if (!mounted) return;
                  _controller.play();
                  // if (widget.index == 0) {
                  //   setState(() {
                  //     _controller.play();
                  //   });
                  // }
                }
              } else {
                if (!mounted) return;
                setState(() {
                  _controller.pause();
                });
              }
            },
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(children: [
                GestureDetector(
                    onTap: () {
                      // if (_controller.value.isPlaying) {
                      //   setState(() {
                      //     userPaused = true;
                      //     _controller.pause();
                      //   });
                      // } else {
                      //   setState(() {
                      //     _controller.play();
                      //     userPaused = false;
                      //   });
                      // }
                      goTo(
                          context,
                          VideosScreen(
                            clickedVideo: widget.property,
                          ),
                          false);
                    },
                    child: VideoPlayer(_controller)),
                Positioned(
                    top: 10,
                    left: 5.0,
                    child: GestureDetector(
                      onTap: () {
                        if (soundEnabled == true) {
                          setState(() {
                            soundEnabled = false;
                          });
                        } else {
                          setState(() {
                            soundEnabled = true;
                          });
                        }
                        if (soundEnabled) {
                          setState(() {
                            _controller.setVolume(1.0);
                          });
                        } else {
                          setState(() {
                            _controller.setVolume(0.0);
                          });
                        }
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        child: CircleAvatar(
                          backgroundColor: black.withOpacity(.5),
                          child: Icon(
                            soundEnabled == true
                                ? Icons.volume_up
                                : Icons.volume_mute,
                            color: white,
                            size: 12,
                          ),
                        ),
                      ),
                    ))
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
