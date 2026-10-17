import 'package:eafind/models/user_model.dart';
import 'package:flutter/material.dart';

class TaggedAgentsProvider extends ChangeNotifier {
  List<UserModel> taggedAgents = [];
  addTaggedAgent(List<UserModel> agents) {
    taggedAgents = agents;
    notifyListeners();
  }

  getTaggedAgents() {
    return taggedAgents;
  }

  clearTaggedAgents() {
    taggedAgents = [];
    notifyListeners();
  }
}
