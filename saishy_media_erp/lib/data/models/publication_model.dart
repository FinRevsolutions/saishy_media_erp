class PublicationModel {
  final String id;
  final String roNumber;
  final String partyName;
  final String mediaHouseName;
  final String agencyName;
  final DateTime publicationDate;
  final String status;
  final String? publishedEdition;
  final String? proofUrl;
  final String? epaper_url;
  final String? cuttingUrl;
  final String? notes;
  final DateTime? statusUpdatedAt;
  final String? statusUpdatedBy;
  final DateTime? createdAt;

  const PublicationModel({
    required this.id,
    required this.roNumber,
    required this.partyName,
    required this.mediaHouseName,
    required this.agencyName,
    required this.publicationDate,
    this.status = 'Draft',
    this.publishedEdition,
    this.proofUrl,
    this.epaper_url,
    this.cuttingUrl,
    this.notes,
    this.statusUpdatedAt,
    this.statusUpdatedBy,
    this.createdAt,
  });

  bool get isPublished => status == 'Published';
  bool get isBilled => status == 'Billed';
  bool get isPaid => status == 'Paid';

  int get statusIndex {
    const statuses = ['Draft', 'Sent', 'Accepted', 'Published', 'Billed', 'Paid'];
    return statuses.indexOf(status);
  }

  factory PublicationModel.fromJson(Map<String, dynamic> json) => PublicationModel(
    id: json['id']?.toString() ?? '',
    roNumber: json['ro_number']?.toString() ?? '',
    partyName: json['party_name']?.toString() ?? '',
    mediaHouseName: json['media_house_name']?.toString() ?? '',
    agencyName: json['agency_name']?.toString() ?? '',
    publicationDate: _parseDate(json['publication_date']) ?? DateTime.now(),
    status: json['status']?.toString() ?? 'Draft',
    publishedEdition: _str(json['published_edition']),
    proofUrl: _str(json['proof_url']),
    epaper_url: _str(json['epaper_url']),
    cuttingUrl: _str(json['cutting_url']),
    notes: _str(json['notes']),
    statusUpdatedAt: _parseDate(json['status_updated_at']),
    statusUpdatedBy: _str(json['status_updated_by']),
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ro_number': roNumber,
    'party_name': partyName,
    'media_house_name': mediaHouseName,
    'agency_name': agencyName,
    'publication_date': publicationDate.toIso8601String().split('T')[0],
    'status': status,
    'published_edition': publishedEdition ?? '',
    'proof_url': proofUrl ?? '',
    'epaper_url': epaper_url ?? '',
    'cutting_url': cuttingUrl ?? '',
    'notes': notes ?? '',
    'status_updated_at': statusUpdatedAt?.toIso8601String() ?? '',
    'status_updated_by': statusUpdatedBy ?? '',
    'created_at': createdAt?.toIso8601String() ?? '',
  };

  PublicationModel copyWith({
    String? id, String? roNumber, String? partyName, String? mediaHouseName,
    String? agencyName, DateTime? publicationDate, String? status,
    String? publishedEdition, String? proofUrl, String? epaperUrl,
    String? cuttingUrl, String? notes, DateTime? statusUpdatedAt,
    String? statusUpdatedBy,
  }) => PublicationModel(
    id: id ?? this.id,
    roNumber: roNumber ?? this.roNumber,
    partyName: partyName ?? this.partyName,
    mediaHouseName: mediaHouseName ?? this.mediaHouseName,
    agencyName: agencyName ?? this.agencyName,
    publicationDate: publicationDate ?? this.publicationDate,
    status: status ?? this.status,
    publishedEdition: publishedEdition ?? this.publishedEdition,
    proofUrl: proofUrl ?? this.proofUrl,
    epaper_url: epaperUrl ?? this.epaper_url,
    cuttingUrl: cuttingUrl ?? this.cuttingUrl,
    notes: notes ?? this.notes,
    statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
    statusUpdatedBy: statusUpdatedBy ?? this.statusUpdatedBy,
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
      identical(this, other) || other is PublicationModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
