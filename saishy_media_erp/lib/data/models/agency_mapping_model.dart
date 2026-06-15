class AgencyMappingModel {
  final String id;
  final String mediaHouseId;
  final String mediaHouseName;
  final String agencyName;
  final String? agencyAddress;
  final String? agencyGstin;
  final String? agencyPhone;
  final String? agencyEmail;
  final bool isDefault;
  final DateTime? createdAt;

  const AgencyMappingModel({
    required this.id,
    required this.mediaHouseId,
    required this.mediaHouseName,
    required this.agencyName,
    this.agencyAddress,
    this.agencyGstin,
    this.agencyPhone,
    this.agencyEmail,
    this.isDefault = false,
    this.createdAt,
  });

  factory AgencyMappingModel.fromJson(Map<String, dynamic> json) => AgencyMappingModel(
    id: json['id']?.toString() ?? '',
    mediaHouseId: json['media_house_id']?.toString() ?? '',
    mediaHouseName: json['media_house_name']?.toString() ?? '',
    agencyName: json['agency_name']?.toString() ?? '',
    agencyAddress: _str(json['agency_address']),
    agencyGstin: _str(json['agency_gstin']),
    agencyPhone: _str(json['agency_phone']),
    agencyEmail: _str(json['agency_email']),
    isDefault: json['is_default']?.toString().toLowerCase() == 'true',
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'media_house_id': mediaHouseId,
    'media_house_name': mediaHouseName,
    'agency_name': agencyName,
    'agency_address': agencyAddress ?? '',
    'agency_gstin': agencyGstin ?? '',
    'agency_phone': agencyPhone ?? '',
    'agency_email': agencyEmail ?? '',
    'is_default': isDefault.toString(),
    'created_at': createdAt?.toIso8601String() ?? '',
  };

  AgencyMappingModel copyWith({
    String? id, String? mediaHouseId, String? mediaHouseName,
    String? agencyName, String? agencyAddress, String? agencyGstin,
    String? agencyPhone, String? agencyEmail, bool? isDefault,
  }) => AgencyMappingModel(
    id: id ?? this.id,
    mediaHouseId: mediaHouseId ?? this.mediaHouseId,
    mediaHouseName: mediaHouseName ?? this.mediaHouseName,
    agencyName: agencyName ?? this.agencyName,
    agencyAddress: agencyAddress ?? this.agencyAddress,
    agencyGstin: agencyGstin ?? this.agencyGstin,
    agencyPhone: agencyPhone ?? this.agencyPhone,
    agencyEmail: agencyEmail ?? this.agencyEmail,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt,
  );

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AgencyMappingModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
