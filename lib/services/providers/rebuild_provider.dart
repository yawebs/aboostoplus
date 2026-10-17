import 'package:flutter/material.dart';

class RebuildProvider with ChangeNotifier {
  bool rebuild = false;
  setRebuild(value) {
    rebuild = value;
    notifyListeners();
  }

  getRebuild() {
    return rebuild;
  }
}
