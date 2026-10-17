import 'dart:convert';

import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/models/user_model.dart';

class PropertyModel {
  var id;
  String title;
  String description;
  String category;
  String ownerId;
  String location;
  List requirements;
  var amount;
  String userType;
  List images;
  int rooms;
  int bathrooms;
  bool available;
  String dateCreated;
  String userName;
  var community;
  int colorCode;
  var taggedUser;
  int isHouse;
  var city;
  int cautionFee;
  int legalFee;
  int agentFee;
  int isVideo;
  var propertyOwner;
  String status;
  String? statusReason;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.ownerId,
    required this.location,
    required this.requirements,
    required this.amount,
    required this.userType,
    required this.images,
    required this.rooms,
    required this.bathrooms,
    required this.available,
    required this.dateCreated,
    required this.userName,
    required this.community,
    required this.colorCode,
    required this.taggedUser,
    required this.isHouse,
    required this.city,
    required this.cautionFee,
    required this.legalFee,
    required this.agentFee,
    required this.isVideo,
    this.propertyOwner,
    this.status = 'active',
    this.statusReason,
  });

  factory PropertyModel.fromMap(var map) {
    return PropertyModel(
      id: map['id'],
      title: map['title'],
      description: map['houseDesc'],
      category: map['category'],
      ownerId: map['ownerId'],
      location: map['hLocation'],
      requirements: json.decode(map['requirements']),
      amount: map['amount'],
      userType: map['userType'],
      images: json.decode(map['images']),
      rooms: map['rooms'],
      bathrooms: map['bathrooms'],
      available: map['available'] == 1 ? true : false,
      dateCreated: map['dateCreated'],
      userName: map['userName'],
      community: map['community'] ?? 'Unknown',
      colorCode: map['color_code'],
      taggedUser: map['tagged_userId'],
      isHouse: map['is_house'],
      city: map['hCity'] ?? '',
      cautionFee: map['cautionFee'],
      legalFee: map['legalFee'],
      agentFee: map['agentFee'],
      isVideo: map['isVideo'],
      propertyOwner:
          map['propertyOwnerData'] == null ? null : map['propertyOwnerData'],
      status: map['status'] ?? 'active',
      statusReason: map['status_reason'],
    );
  }

  bool get isServiceApartment => category == kServiceApartment;

  // Service apartments are short-stay rentals priced per night.
  String get priceSuffix => isServiceApartment ? ' / night' : '';

  bool get isActive => status == 'active';
  bool get isUnderReview => status == 'under_review';
  bool get isRemoved => status == 'removed';
}
