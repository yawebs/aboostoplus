import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/services/fservice.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../models/new_products_model.dart';
import '../models/property_model.dart';
import '../providers/usermodel_provider.dart';

class DbServices {
  // Future<UserModel?> getUser(userId) async {
  //   UserModel? user;
  //   DocumentSnapshot snapshot = await Fservice.usersRef.doc(userId).get();
  //   if (snapshot.exists) {
  //     // UserModel fUser = UserModel.fromDoc(snapshot);
  //     // user = fUser;
  //   }

  //   return user;
  // }

  static Future<List<UserModel>> searchAgents(keyword) async {
    List<UserModel> users = [];
    QuerySnapshot snapshot =
        await Fservice.usersRef.where('search', arrayContains: keyword).get();

    if (snapshot.docs.isNotEmpty) {
      for (var data in snapshot.docs) {
        // UserModel userModel = UserModel.fromDoc(data);
        // users.add(userModel);
      }
    }

    return users;
  }

  Future<bool> checkUserExistByEmail(email) async {
    bool exist = false;
    QuerySnapshot snapshot = await Fservice.usersRef
        .where(
          'email',
          isEqualTo: email,
        )
        .limit(1)
        .get();
    if (snapshot.docs.length > 0) {
      exist = true;
    }
    return exist;
  }

  static Future<List<PropertyModel>> getProperties(
      propertyType, limit, context) async {
    List<PropertyModel> propertiesData = [];
    UserModel? user =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    try {
      FormData _formdata =
          FormData.fromMap({'propertyType': propertyType, 'limit': limit});
      if (user != null) {
        _formdata.fields.add(MapEntry('userId', user.id));
      }
      var response =
          await Dio().post(endPoint('get-properties.php'), data: _formdata);
      List<PropertyModel> pp = [];
      if (response.data['status'] == 'Success') {
        for (var property in response.data['data']) {
          PropertyModel data = PropertyModel.fromMap(property);
          pp.add(data);
        }
        debugPrint(
            'Not successful: getProperties is not Successfull ${response}');
        propertiesData = pp;
      } else {
        debugPrint('Not successful: getProperties is not Successfull');
      }
    } catch (e, stack) {
      debugPrint(
          'Error Fetching Properties: ${e.toString()} Response is $stack');
    }
    return propertiesData;
  }

  static Future<List<NewProductsModel>> getProducts(
      limit, String category) async {
    List<NewProductsModel> productsData = [];
    try {
      FormData _formdata = FormData.fromMap(
          {'limit': limit, 'get_products': true, 'productType': category});
      var response =
          await Dio().post(endPoint('get-properties.php'), data: _formdata);
      debugPrint('Fetching Products: ${response.data} ');
      if (response.data['status'] == 'Success') {
        for (var product in response.data['data']) {
          NewProductsModel data = NewProductsModel.fromJson(product);
          productsData.add(data);
        }
      } else {
        debugPrint('Not successful: getProducts is not Successfull');
      }
    } catch (e, stack) {
      debugPrint('Error Fetching Products: ${e.toString()} Response is $stack');
    }
    return productsData;
  }

  static Future<List<NewProductsModel>> getRelatedProducts(
      limit, category, itemId) async {
    List<NewProductsModel> productsData = [];
    try {
      FormData _formdata = FormData.fromMap({
        'limit': limit,
        'get_products': true,
        'related_products': category,
        'item_id': itemId
      });
      var response =
          await Dio().post(endPoint('get-properties.php'), data: _formdata);

      if (response.data['status'] == 'Success') {
        for (var product in response.data['data']) {
          NewProductsModel data = NewProductsModel.fromJson(product);
          productsData.add(data);
        }
      } else {
        debugPrint('Not successful: getProducts is not Successfull');
      }
    } catch (e, stack) {
      debugPrint('Error Fetching Products: ${e.toString()} Response is $stack');
    }
    return productsData;
  }

  static Future<List<UserModel>> getAllUsers() async {
    List<UserModel> users = [];
    QuerySnapshot snapshot = await Fservice.usersRef.get();
    debugPrint('Snapshot docs length is ${snapshot.docs.length}');
    snapshot.docs.forEach((doc) {
      // users.add(UserModel.fromDoc(doc));
    });
    return users;
  }

  static Future<List<PropertyModel>> getPropertiesByCategories(
      propertyType, limit) async {
    List<PropertyModel> propertiesData = [];
    try {
      FormData _formdata =
          FormData.fromMap({'category': propertyType, 'limit': limit});
      var response =
          await Dio().post(endPoint('get-properties.php'), data: _formdata);
      List<PropertyModel> pp = [];
      if (response.data['status'] == 'Success') {
        for (var property in response.data['data']) {
          PropertyModel data = PropertyModel.fromMap(property);
          pp.add(data);
        }

        propertiesData = pp;
      } else {
        debugPrint('Not successful: getProperties is not Successfull');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return propertiesData;
  }

  static Future<List<PropertyModel>> getPropertyVideosOnly(
      propertyType, limit) async {
    List<PropertyModel> propertiesData = [];
    try {
      FormData _formdata = FormData.fromMap(
          {'property_videos_only': propertyType, 'limit': limit});
      var response =
          await Dio().post(endPoint('get-properties.php'), data: _formdata);
      List<PropertyModel> pp = [];
      if (response.data['status'] == 'Success') {
        for (var property in response.data['data']) {
          PropertyModel data = PropertyModel.fromMap(property);
          pp.add(data);
        }

        propertiesData = pp;
      } else {
        debugPrint('Not successful: getProperties is not Successfull');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return propertiesData;
  }

  static Future<PropertyModel?> getSingleProperty(propertyId) async {
    PropertyModel? propertyModel;
    try {
      FormData formData =
          FormData.fromMap({'single_property': 1, 'propertyId': propertyId});
      var response =
          await Dio().post(endPoint('get-properties.php'), data: formData);
      if (response.data['status'] == 'Success') {
        PropertyModel data = PropertyModel.fromMap(response.data['data']);
        propertyModel = data;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return propertyModel;
  }

  static setDefaultBank(ownerid, id) async {
    Dio _dio = Dio();
    var data;
    try {
      FormData _formData =
          FormData.fromMap({'update-bank': true, 'ownerId': ownerid, 'id': id});
      var response = await _dio.post(endPoint('add-bank.php'), data: _formData);
      data = response.data;
    } catch (e) {
      debugPrint(e.toString());
    }
    return data;
  }

  static updateBalance(ownerid, amount) async {
    Dio _dio = Dio();
    var data;
    try {
      FormData _formData = FormData.fromMap(
          {'update_balances': true, 'ownerId': ownerid, 'amount': amount});
      var response =
          await _dio.post(endPoint('new-payment.php'), data: _formData);
      data = response.data;
    } catch (e) {
      debugPrint(e.toString());
    }
    return data;
  }

  static Future<int> getFollowersCount(agentId) async {
    int followersCount = 0;
    FormData formData = FormData.fromMap({'userId': agentId});
    try {
      var response =
          await Dio().post(endPoint('get-followers.php'), data: formData);
      debugPrint('Printing Response of followers is $response');
      if (response.data['status'] == 'Success') {
        List followers = response.data['data'];

        followersCount = followers.length;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return followersCount;
  }

  static Future<dynamic> getWalletBalance(ownerId) async {
    var data;
    FormData formData =
        FormData.fromMap({'get_wallet_balance': true, 'ownerId': ownerId});
    try {
      var response =
          await Dio().post(endPoint('new-payment.php'), data: formData);
      if (response.data['status'] == true) {
        data = response.data['data'];
      }
      debugPrint('hello data is ${response.data}');
      return data;
    } catch (e) {
      debugPrint('Oops error: ${e.toString()}');
    }
  }

  static Future<dynamic> getCharges(ownerId) async {
    var data;
    FormData formData = FormData.fromMap({'get_platform_charges': true});
    try {
      var response =
          await Dio().post(endPoint('new-payment.php'), data: formData);
      if (response.data['status'] == true) {
        data = response.data['data'];
      }
      debugPrint('hello data is ${response.data}');
      return data;
    } catch (e) {
      debugPrint('Oops error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getAgentDeals(agentId) async {
    List<dynamic> dealData = [];
    try {
      FormData formData =
          FormData.fromMap({'fetch_agent_deal': 1, 'agent_id': agentId});
      var response = await Dio()
          .post(endPoint('get-deals.php'), data: formData)
          .timeout(Duration(seconds: 20));

      List<dynamic> pp = [];
      if (response.data['status'] == 'Success') {
        for (var data in response.data['data']) {
          pp.add(data);
        }

        dealData = pp;
      } else {
        debugPrint('Not successful: getting agent deals is not Successfull');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return dealData;
  }

  static Future<List<dynamic>> getCustomerDeals(userId) async {
    List<dynamic> dealData = [];
    try {
      FormData formData =
          FormData.fromMap({'fetch_customer_deal': 1, 'customer_id': userId});
      var response = await Dio()
          .post(endPoint('get-deals.php'), data: formData)
          .timeout(Duration(seconds: 20));

      List<dynamic> pp = [];
      if (response.data['status'] == 'Success') {
        for (var data in response.data['data']) {
          pp.add(data);
        }

        dealData = pp;
      } else {
        debugPrint('Not successful: getting agent deals is not Successfull');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return dealData;
  }

  static Future<List<dynamic>> getBanks(userId) async {
    List<dynamic> banks = [];

    FormData _formdata = FormData.fromMap({'ownerId': userId});

    try {
      var response =
          await Dio().post(endPoint('get-banks.php'), data: _formdata);
      if (response.data['status'] == true &&
          response.data['message'] == 'Successful') {
        if (response.data['data'] != null) {
          banks = response.data['data'];
        } else {
          debugPrint('Error: Data is null');
        }
      } else {
        debugPrint(
            'Error: something went wrong: Response Message: ${response.data['message']} Status is ${response.data['status']}');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return banks;
  }

  static Future<List<UserModel>> getAgents() async {
    List<UserModel> agents = [];
    QuerySnapshot snapshot =
        await Fservice.usersRef.where('userType', isEqualTo: 'Agent').get();
    if (snapshot.docs.isNotEmpty) {
      for (var data in snapshot.docs) {
        // UserModel userModel = UserModel.fromDoc(data);
        // agents.add(userModel);
      }
    }
    return agents;
  }

  static Future<List<PropertyModel>> fetchMixed(propertyType, limit) async {
    List<PropertyModel> propertiesData = [];
    try {
      FormData formData =
          FormData.fromMap({'mixed': propertyType, 'limit': limit});
      var response =
          await Dio().post(endPoint('get-properties.php'), data: formData);
      List<PropertyModel> pp = [];
      if (response.data['status'] == 'Success') {
        for (var property in response.data['data']) {
          PropertyModel data = PropertyModel.fromMap(property);
          pp.add(data);
        }

        propertiesData = pp;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return propertiesData;
  }

  static Future<List<PropertyModel>> fetchAgentProperties(
      agentId, limit) async {
    List<PropertyModel> propertiesData = [];
    try {
      FormData formData =
          FormData.fromMap({'agentId': agentId, 'limit': limit});
      var response =
          await Dio().post(endPoint('get-properties.php'), data: formData);
      List<PropertyModel> pp = [];
      debugPrint('Fetching properties for agent ${response.data['data']}');
      if (response.data['status'] == 'Success') {
        for (var property in response.data['data']) {
          PropertyModel data = PropertyModel.fromMap(property);
          pp.add(data);
        }

        propertiesData = pp;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return propertiesData;
  }

  static Future<List<UserModel>> getUserLeads(String uid) async {
    QuerySnapshot snapshot =
        await Fservice.usersRef.where('leadUId', isEqualTo: uid).get();
    List<UserModel> leads = [];
    if (snapshot.docs.isNotEmpty) {
      for (var data in snapshot.docs) {
        // UserModel userModel = UserModel.fromDoc(data);
        // leads.add(userModel);
      }
    }
    return leads;
  }
}
