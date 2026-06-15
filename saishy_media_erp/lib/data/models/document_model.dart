class DocumentModel {
  final String id;
  final String referenceNumber; // RO number or Invoice number
  final String referenceType; // 'RO', 'Invoice', 'Payment'
  final String documentType; // From AppConstants.documentTypes
  final String fileUrl;
  final String? driveFileId;
  final String? fileName;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? description;
  final String? uploadedBy;
  final DateTime? uploadedAt;

  const DocumentModel({
    required this.id,
    required this.referenceNumber,
    required this.referenceType,
    required this.documentType,
    required this.fileUrl,
    this.driveFileId,
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.description,
    this.uploadedBy,
    this.uploadedAt,
  });

  bool get isPdf => mimeType == 'application/pdf' ||
      (fileName?.toLowerCase().endsWith('.pdf') ?? false);
  bool get isImage =>
      mimeType?.startsWith('image/') == true ||
      (fileName?.toLowerCase().endsWith('.jpg') == true) ||
      (fileName?.toLowerCase().endsWith('.jpeg') == true) ||
      (fileName?.toLowerCase().endsWith('.png') == true);

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    id: json['id']?.toString() ?? '',
    referenceNumber: json['reference_number']?.toString() ?? '',
    referenceType: json['reference_type']?.toString() ?? '',
    documentType: json['document_type']?.toString() ?? '',
    fileUrl: json['file_url']?.toString() ?? '',
    driveFileId: _str(json['drive_file_id']),
    fileName: _str(json['file_name']),
    fileSizeBytes: int.tryParse(json['file_size_bytes']?.toString() ?? ''),
    mimeType: _str(json['mime_type']),
    description: _str(json['description']),
    uploadedBy: _str(json['uploaded_by']),
    uploadedAt: _parseDate(json['uploaded_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference_number': referenceNumber,
    'reference_type': referenceType,
    'document_type': documentType,
    'file_url': fileUrl,
    'drive_file_id': driveFileId ?? '',
    'file_name': fileName ?? '',
    'file_size_bytes': fileSizeBytes?.toString() ?? '',
    'mime_type': mimeType ?? '',
    'description': description ?? '',
    'uploaded_by': uploadedBy ?? '',
    'uploaded_at': uploadedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };

  DocumentModel copyWith({
    String? id, String? referenceNumber, String? referenceType,
    String? documentType, String? fileUrl, String? driveFileId,
    String? fileName, int? fileSizeBytes, String? mimeType,
    String? description, String? uploadedBy,
  }) => DocumentModel(
    id: id ?? this.id,
    referenceNumber: referenceNumber ?? this.referenceNumber,
    referenceType: referenceType ?? this.referenceType,
    documentType: documentType ?? this.documentType,
    fileUrl: fileUrl ?? this.fileUrl,
    driveFileId: driveFileId ?? this.driveFileId,
    fileName: fileName ?? this.fileName,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    mimeType: mimeType ?? this.mimeType,
    description: description ?? this.description,
    uploadedBy: uploadedBy ?? this.uploadedBy,
    uploadedAt: uploadedAt,
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
      identical(this, other) || other is DocumentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
