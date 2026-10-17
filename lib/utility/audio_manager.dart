import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class AudioManager {
  static final sfx = ValueNotifier(true);
  static final bgm = ValueNotifier(true);
  static Future<void> init() async {
    FlameAudio.bgm.initialize();

    FlameAudio.audioCache.loadAll([
      "like.mp3",
    ]);
  }

  static Future<void> disposePlayer() async {
    FlameAudio.bgm.dispose();
  }

  static void playSfx(String file) {
    if (sfx.value) {
      FlameAudio.play(file);
    }
  }

  static void playBgm(String file) {
    if (bgm.value) {
      FlameAudio.bgm.play(file, volume: 1);
    }
  }

  static void pauseBgm() {
    FlameAudio.bgm.pause();
  }

  static void resumeBgm() {
    if (bgm.value) {
      FlameAudio.bgm.resume();
    }
  }

  static void stopBgm() {
    FlameAudio.bgm.stop();
  }

  static bool isPlayingSound() {
    return FlameAudio.bgm.isPlaying;
  }
}
