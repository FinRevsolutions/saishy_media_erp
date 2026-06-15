class MediaHouseModel {
  final String id;
  final String name;
  final String? edition;
  final String? language;
  final String? contactPerson;
  final String? mobile;
  final String? email;
  final double gstPercentage;
  final String? address;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;

  const MediaHouseModel({
    required this.id,
    required this.name,
    this.edition,
    this.language,
    this.contactPerson,
    this.mobile,
    this.email,
    this.gstPercentage = 5.0,
    this.address,
    this.notes,
    this.isActive = true,
    this.createdAt,
  });

  String get displayName =>
      (edition != null && edition!.isNotEmpty) ? '$name ($edition)' : name;

  factory MediaHouseModel.fromJson(Map<String, dynamic> json) => MediaHouseModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    edition: _str(json['edition']),
    language: _str(json['language']),
    contactPerson: _str(json['contact_person']),
    mobile: _str(json['mobile']),
    email: _str(json['email']),
    gstPercentage: double.tryParse(json['gst_percentage']?.toString() ?? '') ?? 5.0,
    address: _str(json['address']),
    notes: _str(json['notes']),
    isActive: json['is_active']?.toString().toLowerCase() != 'false',
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'edition': edition ?? '',
    'language': language ?? '',
    'contact_person': contactPerson ?? '',
    'mobile': mobile ?? '',
    'email': email ?? '',
    'gst_percentage': gstPercentage.toString(),
    'address': address ?? '',
    'notes': notes ?? '',
    'is_active': isActive.toString(),
    'created_at': createdAt?.toIso8601String() ?? '',
  };

  MediaHouseModel copyWith({
    String? id, String? name, String? edition, String? language,
    String? contactPerson, String? mobile, String? email,
    double? gstPercentage, String? address, String? notes, bool? isActive,
  }) => MediaHouseModel(
    id: id ?? this.id,
    name: name ?? this.name,
    edition: edition ?? this.edition,
    language: language ?? this.language,
    contactPerson: contactPerson ?? this.contactPerson,
    mobile: mobile ?? this.mobile,
    email: email ?? this.email,
    gstPercentage: gstPercentage ?? this.gstPercentage,
    address: address ?? this.address,
    notes: notes ?? this.notes,
    isActive: isActive ?? this.isActive,
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
      identical(this, other) || other is MediaHouseModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
