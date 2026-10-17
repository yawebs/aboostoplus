import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/providers/userId_provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortid/shortid.dart';

import '../services/fservice.dart';
import '../services/push_notification_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future signupUserEndpoint(FormData formData) async {
    try {
      var result =
          await Dio().post(endPoint('upload-images.php'), data: formData);

      debugPrint('resultData: ${result.data}');
      return result;
    } catch (e, stack) {
      debugPrint('Error Catched: $e Stack is $stack');
    }
  }

  Future loginUserEndpoint(String email, String password) async {
    try {
      String? deviceId = await PushNotificationService.getDeviceToken();
      await FirebaseMessaging.instance.subscribeToTopic('offers');
      FormData formData = FormData.fromMap({
        'action': 'login',
        'email': email,
        'password': password,
        'notification_token': deviceId
      });
      var result = await Dio().post(
        endPoint('auth-user.php'),
        data: formData,
      );
      debugPrint('resultData: ${result.data}');
      return result;
    } catch (e, stack) {
      debugPrint('Error Catched: $e Stack is $stack');
    }
  }

  Future<void> logout(context) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    Provider.of<UsermodelProvider>(context, listen: false).clear();
  }

  Future getUserEndpoint(String email) async {
    try {
      FormData formData = FormData.fromMap(
          {'get_user': 'fetch', 'email': email, 'type': 'email'});
      var result = await Dio().post(
        endPoint('auth-user.php'),
        data: formData,
      );
      debugPrint('resultData: ${result.data}');
      return result;
    } on DioException catch (e) {
      debugPrint('This is dio Exception ${e.message}');
    } catch (e, stack) {
      debugPrint('Error Catched: $e Stack is $stack');
    }
  }

  static Future getUserById(String id) async {
    try {
      FormData formData =
          FormData.fromMap({'get_user': 'fetch', 'id': id, 'type': 'id'});
      var result = await Dio().post(
        endPoint('auth-user.php'),
        data: formData,
      );
      debugPrint('resultData: ${result.data}');
      return result;
    } catch (e, stack) {
      debugPrint('Error Catched: $e Stack is $stack');
    }
  }

  Future signup(
      {firstname,
      lastname,
      email,
      phone,
      address,
      state,
      city,
      userType,
      password,
      notificationToken,
      context,
      leadId}) async {
    var result = '';
    List search = [];
    search.add(firstname.toString().toLowerCase());
    search.add(lastname.toString().toLowerCase());
    search.add(email.toString().toLowerCase());
    search.add(phone.toString().toLowerCase());
    search.add(address.toString().toLowerCase());
    search.add(state.toString().toLowerCase());
    search.add(city.toString().toLowerCase());
    try {
      await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .then((value) async => {
                Provider.of<UseridProvider>(context, listen: false)
                    .setUserId(value.user!.uid),
                await Fservice.usersRef.doc(value.user!.uid).set({
                  'firstname': firstname,
                  'lastname': lastname,
                  'email': email,
                  'phone': phone,
                  'notificationToken': notificationToken,
                  'createdAt': DateTime.now(),
                  'profileImage': '',
                  'search': search,
                  'userType': userType,
                  'address': address,
                  'state': state,
                  'city': city,
                  'uid': shortid.generate(),
                  'leadUId': leadId ?? '',
                })
              });

      result = "Success";
    } catch (e) {
      result = e.toString();
      debugPrint('Error is ${e.toString()}');
    }
    return result;
  }

  Future loginUser({email, password}) async {
    String result = '';
    try {
      UserCredential authResult = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (authResult.user == null) {
        result = 'not succesful';
      } else {
        result = 'Success';
      }
    } catch (e) {
      if (e.toString().contains('invalid-email')) {
        result = 'Please provide a valid email address';
      } else if (e.toString().contains('user-disabled')) {
        result = 'This account has been disabled';
      } else if (e.toString().contains('user-not-found')) {
        result = 'This account does not exist';
      } else if (e.toString().contains('wrong-password')) {
        result = 'invalid password';
      } else {
        debugPrint('Error is ${e.toString()}');
        result = e.toString();
      }
    }
    return result;
  }
}
