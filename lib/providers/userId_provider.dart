import 'package:flutter/material.dart';

class UseridProvider with ChangeNotifier {
  String _userId = '';
  String get userId => _userId;

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }
}
