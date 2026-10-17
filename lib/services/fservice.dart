import 'package:cloud_firestore/cloud_firestore.dart';

class Fservice {
  static final fstore = FirebaseFirestore.instance;

  static final usersRef = fstore.collection('users');
  static final eventsRef = fstore.collection('events');
}
