import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int screen = 0;
  setScreen(value) {
    screen = value;
    notifyListeners();
  }

  getScreen() {
    return screen;
  }
}
