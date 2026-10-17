class UserModel {
  String id;
  String firstName;
  String lastName;
  String email;
  String createdAt;
  var profileImage;
  String phone;
  String userType;
  String address;
  String state;
  String city;
  String userName;
  var notificationToken;
  var uid;
  var leadId;
  String password;
  String accountStatus;
  UserModel(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.createdAt,
      required this.profileImage,
      required this.phone,
      required this.userType,
      required this.address,
      required this.state,
      required this.city,
      required this.userName,
      this.uid,
      this.leadId,
      this.notificationToken,
      required this.password,
      this.accountStatus = 'active'});
//json data
  Map<String, dynamic> toJson() => {
        'uniqueId': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'createdAt': createdAt,
        'profileImage': profileImage,
        'phone': phone,
        'user_type': userType,
        'uAddress': address,
        'uState': state,
        'city': city,
        'userName': userName,
        'uid': uid,
        'leadId': leadId,
        'notification_token': notificationToken,
        'user_pwd': password,
        'account_status': accountStatus,
      };
  //from json

  Map<String, dynamic> fromJson(Map<String, dynamic> json) => {
        'id': json['uniqueId'],
        'firstName': json['firstname'],
        'lastName': json['lastname'],
        'email': json['email'],
        'createdAt': json['createdAt'],
        'profileImage': json['profileImage'],
        'phone': json['phone'],
        'userType': json['userType'],
        'address': json['uAddress'],
        'state': json['uState'],
        'city': json['city'],
        'userName': json['userName'],
        'uid': json['uid'],
        'leadId': json['leadUid'],
        'notification_token': json['notification_token'],
        'user_pwd': json['user_pwd'],
        'accountStatus': json['account_status'] ?? 'active',
      };

  factory UserModel.fromDoc(Map<String, dynamic> json) => UserModel(
        id: json['uniqueId'],
        firstName: json['firstname'],
        lastName: json['lastname'],
        email: json['email'],
        createdAt: json['createdAt'],
        profileImage: json['profileImage'],
        phone: json['phone'],
        userType: json['userType'],
        address: json['uAddress'],
        state: json['uState'],
        city: json['city'],
        userName: json['firstname'],
        uid: json['uniqueId'],
        leadId: json['leadUid'],
        notificationToken: json['notification_token'],
        password: json['user_pwd'],
        accountStatus: json['account_status'] ?? 'active',
      );
  factory UserModel.fromDoc2(Map<String, dynamic> json) => UserModel(
        id: json['uniqueId'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'],
        createdAt: json['createdAt'],
        profileImage: json['profileImage'],
        phone: json['phone'],
        userType: json['user_type'],
        address: json['uAddress'],
        state: json['uState'],
        city: json['city'],
        userName: json['first_name'],
        uid: json['uid'],
        leadId: json['leadId'],
        notificationToken: json['notification_token'],
        password: json['user_pwd'],
        accountStatus: json['account_status'] ?? 'active',
      );

  bool get isActive => accountStatus == 'active';
  bool get isUnderReview => accountStatus == 'under_review';
  bool get isSuspended => accountStatus == 'suspended';
}
