import 'dart:convert';

import 'package:eafind/models/user_model.dart';

class NewProductsModel {
  List images;
  String name;
  var price;
  String discount;
  String description;
  String category;
  String state;
  String area;
  String ownerId;
  int id;
  var status;
  UserModel ownerData;

  NewProductsModel(
      {required this.images,
      required this.name,
      required this.price,
      required this.discount,
      required this.description,
      required this.category,
      required this.state,
      required this.area,
      required this.ownerId,
      this.status,
      required this.ownerData,
      required this.id});

  factory NewProductsModel.fromJson(Map<String, dynamic> doc) {
    return NewProductsModel(
      images: json.decode(doc["item_images"]),
      name: doc["item_name"],
      price: doc["amount"],
      discount: '',
      description: doc["item_desc"],
      category: doc["item_category"],
      state: doc["pState"],
      area: doc["item_location"],
      ownerId: doc["ownerId"],
      status: doc["status"],
      id: doc["id"],
      ownerData: UserModel.fromDoc2(json.decode(doc["item_owner_data"])),
    );
  }
}
