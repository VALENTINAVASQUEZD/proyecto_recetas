import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String username;
  
  @HiveField(2)
  String password;
  
  @HiveField(3)
  String region;
  
  @HiveField(4)
  String? profileImagePath;
  
  @HiveField(5)
  String? appwriteId;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.region,
    this.profileImagePath,
    this.appwriteId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'region': region,
      'profileImagePath': profileImagePath,
      'appwriteId': appwriteId,
    };
  }
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      password: json['password'] ?? '',
      region: json['region'],
      profileImagePath: json['profileImagePath'],
      appwriteId: json['appwriteId'],
    );
  }
}
