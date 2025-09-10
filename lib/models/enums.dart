enum UserType {
  waris,
  staff, client,
}

extension UserTypeExtension on UserType {
  String get value {
    switch (this) {
      case UserType.client:
        return 'client';
      case UserType.waris:
        return 'waris';
      case UserType.staff:
        return 'staff';
    }
  }

  static UserType fromString(String value) {
    switch (value) {
      case 'waris':
        return UserType.waris;
      case 'staff':
        return UserType.staff;
      default:
        throw ArgumentError('Invalid UserType: $value');
    }
  }
}

enum ServiceType {
  fullService,
  deliveryOnly,
}

extension ServiceTypeExtension on ServiceType {
  String get value {
    switch (this) {
      case ServiceType.fullService:
        return 'fullService';
      case ServiceType.deliveryOnly:
        return 'deliveryOnly';
    }
  }

  String get displayName {
    switch (this) {
      case ServiceType.fullService:
        return 'Full Service';
      case ServiceType.deliveryOnly:
        return 'Penghantaran Sahaja';
    }
  }

  static ServiceType fromString(String value) {
    switch (value) {
      case 'fullService':
        return ServiceType.fullService;
      case 'deliveryOnly':
        return ServiceType.deliveryOnly;
      default:
        throw ArgumentError('Invalid ServiceType: $value');
    }
  }
}

enum Gender {
  lelaki,
  perempuan,
}

extension GenderExtension on Gender {
  String get value {
    switch (this) {
      case Gender.lelaki:
        return 'lelaki';
      case Gender.perempuan:
        return 'perempuan';
    }
  }

  String get displayName {
    switch (this) {
      case Gender.lelaki:
        return 'Lelaki';
      case Gender.perempuan:
        return 'Perempuan';
    }
  }

  static Gender fromString(String value) {
    switch (value) {
      case 'lelaki':
        return Gender.lelaki;
      case 'perempuan':
        return Gender.perempuan;
      default:
        throw ArgumentError('Invalid Gender: $value');
    }
  }
}

enum CaseStatus {
  pending,
  accepted,
  declined,
  completed,
}

extension CaseStatusExtension on CaseStatus {
  String get value {
    switch (this) {
      case CaseStatus.pending:
        return 'pending';
      case CaseStatus.accepted:
        return 'accepted';
      case CaseStatus.declined:
        return 'declined';
      case CaseStatus.completed:
        return 'completed';
    }
  }

  // FIX: Make sure displayName is properly implemented
  String get displayName {
    switch (this) {
      case CaseStatus.pending:
        return 'Menunggu';
      case CaseStatus.accepted:
        return 'Diterima';
      case CaseStatus.declined:
        return 'Ditolak';
      case CaseStatus.completed:
        return 'Selesai';
    }
  }

  static CaseStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return CaseStatus.pending;
      case 'accepted':
        return CaseStatus.accepted;
      case 'declined':
        return CaseStatus.declined;
      case 'completed':
        return CaseStatus.completed;
      default:
        return CaseStatus.pending; // Default fallback instead of throwing error
    }
  }
}