class InvoiceModel {
  final String invoiceNumber;
  final String roNumber;
  final String partyId;
  final String partyName;
  final String? partyGstin;
  final String? partyAddress;
  final String mediaHouseId;
  final String mediaHouseName;
  final DateTime publicationDate;
  final DateTime invoiceDate;
  final double amount;
  final double tradeDiscount;
  final double taxableAmount;
  final String gstType; // '5', '18', 'none'
  final double cgst;
  final double sgst;
  final double gstAmount;
  final double totalAmount;
  final double amountPaid;
  final String status; // Pending, Partial, Paid, Overdue
  final bool isGstInvoice;
  final String? createdBy;
  final String? notes;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get balanceAmount => totalAmount - amountPaid;
  bool get isPaid => status == 'Paid';
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != 'Paid';
  }

  const InvoiceModel({
    required this.invoiceNumber,
    required this.roNumber,
    required this.partyId,
    required this.partyName,
    this.partyGstin,
    this.partyAddress,
    required this.mediaHouseId,
    required this.mediaHouseName,
    required this.publicationDate,
    required this.invoiceDate,
    required this.amount,
    required this.tradeDiscount,
    required this.taxableAmount,
    required this.gstType,
    required this.cgst,
    required this.sgst,
    required this.gstAmount,
    required this.totalAmount,
    this.amountPaid = 0,
    this.status = 'Pending',
    this.isGstInvoice = true,
    this.createdBy,
    this.notes,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
    invoiceNumber: json['invoice_number']?.toString() ?? '',
    roNumber: json['ro_number']?.toString() ?? '',
    partyId: json['party_id']?.toString() ?? '',
    partyName: json['party_name']?.toString() ?? '',
    partyGstin: _str(json['party_gstin']),
    partyAddress: _str(json['party_address']),
    mediaHouseId: json['media_house_id']?.toString() ?? '',
    mediaHouseName: json['media_house_name']?.toString() ?? '',
    publicationDate: _parseDate(json['publication_date']) ?? DateTime.now(),
    invoiceDate: _parseDate(json['invoice_date']) ?? DateTime.now(),
    amount: _dbl(json['amount']),
    tradeDiscount: _dbl(json['trade_discount']),
    taxableAmount: _dbl(json['taxable_amount']),
    gstType: json['gst_type']?.toString() ?? 'none',
    cgst: _dbl(json['cgst']),
    sgst: _dbl(json['sgst']),
    gstAmount: _dbl(json['gst_amount']),
    totalAmount: _dbl(json['total_amount']),
    amountPaid: _dbl(json['amount_paid']),
    status: json['status']?.toString() ?? 'Pending',
    isGstInvoice: json['is_gst_invoice']?.toString().toLowerCase() != 'false',
    createdBy: _str(json['created_by']),
    notes: _str(json['notes']),
    dueDate: _parseDate(json['due_date']),
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'invoice_number': invoiceNumber,
    'ro_number': roNumber,
    'party_id': partyId,
    'party_name': partyName,
    'party_gstin': partyGstin ?? '',
    'party_address': partyAddress ?? '',
    'media_house_id': mediaHouseId,
    'media_house_name': mediaHouseName,
    'publication_date': publicationDate.toIso8601String().split('T')[0],
    'invoice_date': invoiceDate.toIso8601String().split('T')[0],
    'amount': amount.toStringAsFixed(2),
    'trade_discount': tradeDiscount.toStringAsFixed(2),
    'taxable_amount': taxableAmount.toStringAsFixed(2),
    'gst_type': gstType,
    'cgst': cgst.toStringAsFixed(2),
    'sgst': sgst.toStringAsFixed(2),
    'gst_amount': gstAmount.toStringAsFixed(2),
    'total_amount': totalAmount.toStringAsFixed(2),
    'amount_paid': amountPaid.toStringAsFixed(2),
    'status': status,
    'is_gst_invoice': isGstInvoice.toString(),
    'created_by': createdBy ?? '',
    'notes': notes ?? '',
    'due_date': dueDate?.toIso8601String().split('T')[0] ?? '',
    'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  InvoiceModel copyWith({
    String? invoiceNumber, String? roNumber, String? partyId,
    String? partyName, String? partyGstin, String? partyAddress,
    String? mediaHouseId, String? mediaHouseName, DateTime? publicationDate,
    DateTime? invoiceDate, double? amount, double? tradeDiscount,
    double? taxableAmount, String? gstType, double? cgst, double? sgst,
    double? gstAmount, double? totalAmount, double? amountPaid,
    String? status, bool? isGstInvoice, String? notes, DateTime? dueDate,
  }) => InvoiceModel(
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    roNumber: roNumber ?? this.roNumber,
    partyId: partyId ?? this.partyId,
    partyName: partyName ?? this.partyName,
    partyGstin: partyGstin ?? this.partyGstin,
    partyAddress: partyAddress ?? this.partyAddress,
    mediaHouseId: mediaHouseId ?? this.mediaHouseId,
    mediaHouseName: mediaHouseName ?? this.mediaHouseName,
    publicationDate: publicationDate ?? this.publicationDate,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    amount: amount ?? this.amount,
    tradeDiscount: tradeDiscount ?? this.tradeDiscount,
    taxableAmount: taxableAmount ?? this.taxableAmount,
    gstType: gstType ?? this.gstType,
    cgst: cgst ?? this.cgst,
    sgst: sgst ?? this.sgst,
    gstAmount: gstAmount ?? this.gstAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    amountPaid: amountPaid ?? this.amountPaid,
    status: status ?? this.status,
    isGstInvoice: isGstInvoice ?? this.isGstInvoice,
    notes: notes ?? this.notes,
    dueDate: dueDate ?? this.dueDate,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static double _dbl(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  static DateTime? _parseDate(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InvoiceModel && invoiceNumber == other.invoiceNumber;

  @override
  int get hashCode => invoiceNumber.hashCode;
}
