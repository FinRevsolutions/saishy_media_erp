import '../../core/constants/app_constants.dart';

enum UserRole { superAdmin, admin, operator, accountant }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin: return AppConstants.roleSuperAdmin;
      case UserRole.admin: return AppConstants.roleAdmin;
      case UserRole.operator: return AppConstants.roleOperator;
      case UserRole.accountant: return AppConstants.roleAccountant;
    }
  }

  static UserRole fromString(String s) {
    switch (s) {
      case AppConstants.roleSuperAdmin: return UserRole.superAdmin;
      case AppConstants.roleAdmin: return UserRole.admin;
      case AppConstants.roleOperator: return UserRole.operator;
      case AppConstants.roleAccountant: return UserRole.accountant;
      default: return UserRole.operator;
    }
  }

  bool get canManageUsers => this == UserRole.superAdmin;
  bool get canDeleteRecords => this == UserRole.superAdmin || this == UserRole.admin;
  bool get canCreateRO => this != UserRole.accountant;
  bool get canViewFinancials =>
      this == UserRole.superAdmin || this == UserRole.admin || this == UserRole.accountant;
  bool get canManagePayments =>
      this == UserRole.superAdmin || this == UserRole.admin || this == UserRole.accountant;
  bool get canViewReports => true;
}

class UserModel {
  final String id;
  final String username;
  final String passwordHash;
  final UserRole role;
  final String fullName;
  final String? email;
  final String? mobile;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const UserModel({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.fullName,
    this.email,
    this.mobile,
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
  });

  bool get isLoggedIn => id.isNotEmpty;

  factory UserModel.empty() => const UserModel(
    id: '', username: '', passwordHash: '', role: UserRole.operator, fullName: '');

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    passwordHash: json['password_hash']?.toString() ?? '',
    role: UserRoleExt.fromString(json['role']?.toString() ?? ''),
    fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
    email: json['email']?.toString(),
    mobile: json['mobile']?.toString(),
    isActive: json['is_active']?.toString().toLowerCase() != 'false',
    createdAt: _parseDate(json['created_at']),
    lastLogin: _parseDate(json['last_login']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'password_hash': passwordHash,
    'role': role.label,
    'full_name': fullName,
    'email': email ?? '',
    'mobile': mobile ?? '',
    'is_active': isActive.toString(),
    'created_at': createdAt?.toIso8601String() ?? '',
    'last_login': lastLogin?.toIso8601String() ?? '',
  };

  UserModel copyWith({
    String? id,
    String? username,
    String? passwordHash,
    UserRole? role,
    String? fullName,
    String? email,
    String? mobile,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) => UserModel(
    id: id ?? this.id,
    username: username ?? this.username,
    passwordHash: passwordHash ?? this.passwordHash,
    role: role ?? this.role,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    mobile: mobile ?? this.mobile,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    lastLogin: lastLogin ?? this.lastLogin,
  );

  static DateTime? _parseDate(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
