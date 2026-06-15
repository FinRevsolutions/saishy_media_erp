class PartyModel {
  final String id;
  final String name;
  final String address;
  final String mobile;
  final String? email;
  final bool gstApplicable;
  final String? gstin;
  final String? contactPerson;
  final String? state;
  final String? stateCode;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.mobile,
    this.email,
    this.gstApplicable = false,
    this.gstin,
    this.contactPerson,
    this.state,
    this.stateCode,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String get displayGstin => gstApplicable ? (gstin ?? '-') : 'Non-GST';

  factory PartyModel.fromJson(Map<String, dynamic> json) => PartyModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    mobile: json['mobile']?.toString() ?? '',
    email: _str(json['email']),
    gstApplicable: json['gst_applicable']?.toString().toLowerCase() == 'true' ||
        json['gst_applicable']?.toString() == '1',
    gstin: _str(json['gstin']),
    contactPerson: _str(json['contact_person']),
    state: _str(json['state']),
    stateCode: _str(json['state_code']),
    notes: _str(json['notes']),
    isActive: json['is_active']?.toString().toLowerCase() != 'false',
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'mobile': mobile,
    'email': email ?? '',
    'gst_applicable': gstApplicable.toString(),
    'gstin': gstin ?? '',
    'contact_person': contactPerson ?? '',
    'state': state ?? '',
    'state_code': stateCode ?? '',
    'notes': notes ?? '',
    'is_active': isActive.toString(),
    'created_at': createdAt?.toIso8601String() ?? '',
    'updated_at': DateTime.now().toIso8601String(),
  };

  PartyModel copyWith({
    String? id, String? name, String? address, String? mobile,
    String? email, bool? gstApplicable, String? gstin,
    String? contactPerson, String? state, String? stateCode,
    String? notes, bool? isActive,
  }) => PartyModel(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    mobile: mobile ?? this.mobile,
    email: email ?? this.email,
    gstApplicable: gstApplicable ?? this.gstApplicable,
    gstin: gstin ?? this.gstin,
    contactPerson: contactPerson ?? this.contactPerson,
    state: state ?? this.state,
    stateCode: stateCode ?? this.stateCode,
    notes: notes ?? this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
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
      identical(this, other) || other is PartyModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PartyModel(id: $id, name: $name)';
}
