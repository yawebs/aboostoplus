import 'package:flutter/cupertino.dart';

class LocationProvider with ChangeNotifier {
  Map locationData = {};
  setLoation(Map data) {
    locationData = data;
    notifyListeners();
  }

  getLocation() {
    return locationData;
  }
}
