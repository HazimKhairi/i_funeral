import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class DeathCaseModel {
  final String id;
  final String fullName;
  final int age;
  final Gender gender;
  final String causeOfDeath;
  final String address;
  final String? deliveryLocation;
  final ServiceType serviceType;
  final String warisId;
  final String? staffId;
  final CaseStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const DeathCaseModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.causeOfDeath,
    required this.address,
    this.deliveryLocation,
    required this.serviceType,
    required this.warisId,
    this.staffId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  DeathCaseModel copyWith({
    String? id,
    String? fullName,
    int? age,
    Gender? gender,
    String? causeOfDeath,
    String? address,
    String? deliveryLocation,
    ServiceType? serviceType,
    String? warisId,
    String? staffId,
    CaseStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
  }) {
    return DeathCaseModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      causeOfDeath: causeOfDeath ?? this.causeOfDeath,
      address: address ?? this.address,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      serviceType: serviceType ?? this.serviceType,
      warisId: warisId ?? this.warisId,
      staffId: staffId ?? this.staffId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'gender': gender.value,
      'causeOfDeath': causeOfDeath,
      'address': address,
      'deliveryLocation': deliveryLocation,
      'serviceType': serviceType.value,
      'warisId': warisId,
      'staffId': staffId,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }

  factory DeathCaseModel.fromMap(Map<String, dynamic> map) {
    return DeathCaseModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      age: map['age']?.toInt() ?? 0,
      gender: GenderExtension.fromString(map['gender'] ?? 'lelaki'),
      causeOfDeath: map['causeOfDeath'] ?? '',
      address: map['address'] ?? '',
      deliveryLocation: map['deliveryLocation'],
      serviceType: ServiceTypeExtension.fromString(map['serviceType'] ?? 'fullService'),
      warisId: map['warisId'] ?? '',
      staffId: map['staffId'],
      status: CaseStatusExtension.fromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null ? (map['acceptedAt'] as Timestamp).toDate() : null,
    );
  }

  factory DeathCaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeathCaseModel.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'DeathCaseModel(id: $id, fullName: $fullName, age: $age, gender: $gender, serviceType: $serviceType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeathCaseModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}