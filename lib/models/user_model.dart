import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserType userType;
  final DateTime createdAt;
  final String? phoneNumber;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.createdAt,
    this.phoneNumber,
    this.fcmToken,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
    DateTime? createdAt,
    String? phoneNumber,
     String? fcmToken
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'phoneNumber': phoneNumber,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      userType: UserTypeExtension.fromString(map['userType'] ?? 'waris'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      phoneNumber: map['phoneNumber'],
      fcmToken: map['fcmToken'],
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, userType: $userType, createdAt: $createdAt, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}