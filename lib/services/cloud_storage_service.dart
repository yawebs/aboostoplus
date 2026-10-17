import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class CloudStorageService {
  Future<String?> uploadProfileImage(File image) async {
    String photoId = const Uuid().v4();

    try {
      UploadTask storageUploadTask = FirebaseStorage.instance
          .ref()
          .child("profileImages/profile_$photoId.jpg")
          .putFile(image);
      TaskSnapshot storageSnap = await storageUploadTask;

      String downloadUrl = await storageSnap.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }
}
