class MediaRateCardModel {
  final String id;
  final String mediaHouseId;
  final String mediaHouseName;
  final String rateType;
  final double ratePerUnit;
  final String unit;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const List<String> rateTypes = [
    'Black & White',
    'Color',
    'Front Page',
    'Jacket',
    'Pointer',
    'Government',
    'Classified',
    'Display',
  ];

  static const List<String> units = [
    'col×cm',
    'sq.cm',
    'sq.inch',
    'per insertion',
    'per column',
  ];

  const MediaRateCardModel({
    required this.id,
    required this.mediaHouseId,
    required this.mediaHouseName,
    required this.rateType,
    required this.ratePerUnit,
    this.unit = 'col×cm',
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory MediaRateCardModel.fromJson(Map<String, dynamic> json) =>
      MediaRateCardModel(
        id: json['id']?.toString() ?? '',
        mediaHouseId: json['media_house_id']?.toString() ?? '',
        mediaHouseName: json['media_house_name']?.toString() ?? '',
        rateType: json['rate_type']?.toString() ?? '',
        ratePerUnit: double.tryParse(json['rate_per_unit']?.toString() ?? '') ?? 0,
        unit: json['unit']?.toString() ?? 'col×cm',
        isActive: json['is_active']?.toString().toLowerCase() != 'false',
        notes: _str(json['notes']),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'media_house_id': mediaHouseId,
        'media_house_name': mediaHouseName,
        'rate_type': rateType,
        'rate_per_unit': ratePerUnit.toString(),
        'unit': unit,
        'is_active': isActive.toString(),
        'notes': notes ?? '',
        'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  MediaRateCardModel copyWith({
    String? id,
    String? mediaHouseId,
    String? mediaHouseName,
    String? rateType,
    double? ratePerUnit,
    String? unit,
    bool? isActive,
    String? notes,
  }) =>
      MediaRateCardModel(
        id: id ?? this.id,
        mediaHouseId: mediaHouseId ?? this.mediaHouseId,
        mediaHouseName: mediaHouseName ?? this.mediaHouseName,
        rateType: rateType ?? this.rateType,
        ratePerUnit: ratePerUnit ?? this.ratePerUnit,
        unit: unit ?? this.unit,
        isActive: isActive ?? this.isActive,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MediaRateCardModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MediaRateCardModel($mediaHouseName - $rateType: ₹$ratePerUnit/$unit)';
}
