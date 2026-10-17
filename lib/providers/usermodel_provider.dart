import 'package:eafind/models/user_model.dart';
import 'package:flutter/material.dart';

class UsermodelProvider extends ChangeNotifier {
  UserModel? userModel;

  setUserModel(UserModel user) {
    userModel = user;
    notifyListeners();
  }

  UserModel? getUserModel() {
    return userModel;
  }

  clear() {
    userModel = null;
    notifyListeners();
  }
}
