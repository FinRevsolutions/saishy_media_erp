class PaymentModel {
  final String id;
  final String invoiceNumber;
  final String partyId;
  final String partyName;
  final double amountPaid;
  final double invoiceTotal;
  final DateTime paymentDate;
  final String paymentMode;
  final String? chequeNumber;
  final String? bankName;
  final String? transactionId;
  final String status; // Pending, Partial, Paid, Overdue
  final String? receivedBy;
  final String? notes;
  final String? receiptUrl;
  final DateTime? createdAt;

  double get balanceAmount => invoiceTotal - amountPaid;
  bool get isPaid => status == 'Paid';

  const PaymentModel({
    required this.id,
    required this.invoiceNumber,
    required this.partyId,
    required this.partyName,
    required this.amountPaid,
    required this.invoiceTotal,
    required this.paymentDate,
    required this.paymentMode,
    this.chequeNumber,
    this.bankName,
    this.transactionId,
    this.status = 'Pending',
    this.receivedBy,
    this.notes,
    this.receiptUrl,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id']?.toString() ?? '',
    invoiceNumber: json['invoice_number']?.toString() ?? '',
    partyId: json['party_id']?.toString() ?? '',
    partyName: json['party_name']?.toString() ?? '',
    amountPaid: double.tryParse(json['amount_paid']?.toString() ?? '') ?? 0,
    invoiceTotal: double.tryParse(json['invoice_total']?.toString() ?? '') ?? 0,
    paymentDate: _parseDate(json['payment_date']) ?? DateTime.now(),
    paymentMode: json['payment_mode']?.toString() ?? 'Cash',
    chequeNumber: _str(json['cheque_number']),
    bankName: _str(json['bank_name']),
    transactionId: _str(json['transaction_id']),
    status: json['status']?.toString() ?? 'Pending',
    receivedBy: _str(json['received_by']),
    notes: _str(json['notes']),
    receiptUrl: _str(json['receipt_url']),
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoice_number': invoiceNumber,
    'party_id': partyId,
    'party_name': partyName,
    'amount_paid': amountPaid.toStringAsFixed(2),
    'invoice_total': invoiceTotal.toStringAsFixed(2),
    'payment_date': paymentDate.toIso8601String().split('T')[0],
    'payment_mode': paymentMode,
    'cheque_number': chequeNumber ?? '',
    'bank_name': bankName ?? '',
    'transaction_id': transactionId ?? '',
    'status': status,
    'received_by': receivedBy ?? '',
    'notes': notes ?? '',
    'receipt_url': receiptUrl ?? '',
    'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };

  PaymentModel copyWith({
    String? id, String? invoiceNumber, String? partyId, String? partyName,
    double? amountPaid, double? invoiceTotal, DateTime? paymentDate,
    String? paymentMode, String? chequeNumber, String? bankName,
    String? transactionId, String? status, String? receivedBy, String? notes,
    String? receiptUrl,
  }) => PaymentModel(
    id: id ?? this.id,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    partyId: partyId ?? this.partyId,
    partyName: partyName ?? this.partyName,
    amountPaid: amountPaid ?? this.amountPaid,
    invoiceTotal: invoiceTotal ?? this.invoiceTotal,
    paymentDate: paymentDate ?? this.paymentDate,
    paymentMode: paymentMode ?? this.paymentMode,
    chequeNumber: chequeNumber ?? this.chequeNumber,
    bankName: bankName ?? this.bankName,
    transactionId: transactionId ?? this.transactionId,
    status: status ?? this.status,
    receivedBy: receivedBy ?? this.receivedBy,
    notes: notes ?? this.notes,
    receiptUrl: receiptUrl ?? this.receiptUrl,
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
      identical(this, other) || other is PaymentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
