import '../../core/constants/app_constants.dart';

class ReleaseOrderModel {
  final String roNumber;
  final DateTime date;
  final String partyId;
  final String partyName;
  final String mediaHouseId;
  final String mediaHouseName;
  final String agencyName;
  final DateTime publicationDate;
  final String category;
  final double adWidth;
  final double adHeight;
  final String adUnit; // 'col×cm', 'sq.cm', 'sq.inch'
  final double rate;
  final String gstType; // '5', '18', 'none'
  final String status;
  final String? createdBy;
  final String? notes;
  final bool isDraft;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed financial fields
  double get amount => adWidth * adHeight * rate;
  double get tradeDiscount => amount * AppConstants.tradeDiscountPercent / 100;
  double get taxableAmount => amount - tradeDiscount;
  double get gstPercent {
    switch (gstType) {
      case '5': return 5.0;
      case '18': return 18.0;
      default: return 0.0;
    }
  }
  double get cgst => taxableAmount * gstPercent / 2 / 100;
  double get sgst => taxableAmount * gstPercent / 2 / 100;
  double get gstAmount => taxableAmount * gstPercent / 100;
  double get netPayable => taxableAmount + gstAmount;

  bool get isGst => gstType != 'none' && gstType.isNotEmpty;
  bool get canPublish => status == 'Accepted';
  bool get isPublished => status == 'Published';

  const ReleaseOrderModel({
    required this.roNumber,
    required this.date,
    required this.partyId,
    required this.partyName,
    required this.mediaHouseId,
    required this.mediaHouseName,
    required this.agencyName,
    required this.publicationDate,
    required this.category,
    required this.adWidth,
    required this.adHeight,
    this.adUnit = 'col×cm',
    required this.rate,
    required this.gstType,
    this.status = 'Draft',
    this.createdBy,
    this.notes,
    this.isDraft = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ReleaseOrderModel.fromJson(Map<String, dynamic> json) => ReleaseOrderModel(
    roNumber: json['ro_number']?.toString() ?? '',
    date: _parseDate(json['date']) ?? DateTime.now(),
    partyId: json['party_id']?.toString() ?? '',
    partyName: json['party_name']?.toString() ?? '',
    mediaHouseId: json['media_house_id']?.toString() ?? '',
    mediaHouseName: json['media_house_name']?.toString() ?? '',
    agencyName: json['agency_name']?.toString() ?? '',
    publicationDate: _parseDate(json['publication_date']) ?? DateTime.now(),
    category: json['category']?.toString() ?? '',
    adWidth: double.tryParse(json['ad_width']?.toString() ?? '') ?? 0,
    adHeight: double.tryParse(json['ad_height']?.toString() ?? '') ?? 0,
    adUnit: json['ad_unit']?.toString() ?? 'col×cm',
    rate: double.tryParse(json['rate']?.toString() ?? '') ?? 0,
    gstType: json['gst_type']?.toString() ?? 'none',
    status: json['status']?.toString() ?? 'Draft',
    createdBy: _strN(json['created_by']),
    notes: _strN(json['notes']),
    isDraft: json['is_draft']?.toString().toLowerCase() == 'true',
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'ro_number': roNumber,
    'date': date.toIso8601String().split('T')[0],
    'party_id': partyId,
    'party_name': partyName,
    'media_house_id': mediaHouseId,
    'media_house_name': mediaHouseName,
    'agency_name': agencyName,
    'publication_date': publicationDate.toIso8601String().split('T')[0],
    'category': category,
    'ad_width': adWidth.toString(),
    'ad_height': adHeight.toString(),
    'ad_unit': adUnit,
    'rate': rate.toString(),
    'gst_type': gstType,
    'amount': amount.toStringAsFixed(2),
    'trade_discount': tradeDiscount.toStringAsFixed(2),
    'taxable_amount': taxableAmount.toStringAsFixed(2),
    'gst_amount': gstAmount.toStringAsFixed(2),
    'net_payable': netPayable.toStringAsFixed(2),
    'status': status,
    'created_by': createdBy ?? '',
    'notes': notes ?? '',
    'is_draft': isDraft.toString(),
    'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  ReleaseOrderModel copyWith({
    String? roNumber, DateTime? date, String? partyId, String? partyName,
    String? mediaHouseId, String? mediaHouseName, String? agencyName,
    DateTime? publicationDate, String? category, double? adWidth,
    double? adHeight, String? adUnit, double? rate, String? gstType,
    String? status, String? createdBy, String? notes, bool? isDraft,
  }) => ReleaseOrderModel(
    roNumber: roNumber ?? this.roNumber,
    date: date ?? this.date,
    partyId: partyId ?? this.partyId,
    partyName: partyName ?? this.partyName,
    mediaHouseId: mediaHouseId ?? this.mediaHouseId,
    mediaHouseName: mediaHouseName ?? this.mediaHouseName,
    agencyName: agencyName ?? this.agencyName,
    publicationDate: publicationDate ?? this.publicationDate,
    category: category ?? this.category,
    adWidth: adWidth ?? this.adWidth,
    adHeight: adHeight ?? this.adHeight,
    adUnit: adUnit ?? this.adUnit,
    rate: rate ?? this.rate,
    gstType: gstType ?? this.gstType,
    status: status ?? this.status,
    createdBy: createdBy ?? this.createdBy,
    notes: notes ?? this.notes,
    isDraft: isDraft ?? this.isDraft,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  static String? _strN(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReleaseOrderModel && roNumber == other.roNumber;

  @override
  int get hashCode => roNumber.hashCode;
}
