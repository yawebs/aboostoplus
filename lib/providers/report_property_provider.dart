import 'package:eafind/models/property_model.dart';
import 'package:eafind/models/user_model.dart';
import 'package:flutter/material.dart';

class ReportPropertyProvider with ChangeNotifier {
  PropertyModel? propertyModel;
  String? report;
  UserModel? reporter;
  setProperty(PropertyModel pro) {
    propertyModel = pro;
    notifyListeners();
  }

  setReport(repo) {
    report = repo;
    notifyListeners();
  }

  setReprter(UserModel reporterUser) {
    reporter = reporterUser;
  }

  getProperty() {
    return propertyModel;
  }

  getReport() {
    return report;
  }

  getReporter() {
    return reporter;
  }
}
