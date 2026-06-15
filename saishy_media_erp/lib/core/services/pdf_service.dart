import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/release_order_model.dart';
import '../../data/models/invoice_model.dart';
import '../constants/app_constants.dart';

class PdfService {
  static final PdfService instance = PdfService._internal();
  PdfService._internal();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _currFmt = NumberFormat('#,##,##0.00', 'en_IN');

  // ── Release Order PDF ──────────────────────────────────
  Future<Uint8List> generateRoPdf(
    ReleaseOrderModel ro, {
    Uint8List? logoBytes,
    Uint8List? stampBytes,
    Uint8List? signatureBytes,
  }) async {
    final doc = pw.Document();
    final logoImg = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final stampImg = stampBytes != null ? pw.MemoryImage(stampBytes) : null;
    final signImg = signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildRoHeader(logoImg),
          pw.SizedBox(height: 12),
          _buildRoTitle(ro),
          pw.SizedBox(height: 16),
          _buildRoPartyDetails(ro),
          pw.SizedBox(height: 16),
          _buildRoAdDetails(ro),
          pw.SizedBox(height: 16),
          _buildRoFinancials(ro),
          pw.SizedBox(height: 24),
          _buildRoFooter(signImg, stampImg),
        ],
      ),
    ));

    return doc.save();
  }

  pw.Widget _buildRoHeader(pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(AppConstants.companyName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(AppConstants.companyAddress,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text('Tel: ${AppConstants.companyPhone}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text('Email: ${AppConstants.companyEmail}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text('GSTIN: ${AppConstants.companyGstin}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ]),
        if (logo != null)
          pw.Image(logo, width: 80, height: 80, fit: pw.BoxFit.contain),
      ],
    );
  }

  pw.Widget _buildRoTitle(ReleaseOrderModel ro) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
          top: pw.BorderSide(color: PdfColors.blue800, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('RELEASE ORDER',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800)),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('RO No: ${ro.roNumber}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.Text('Date: ${_dateFmt.format(ro.date)}',
                style: const pw.TextStyle(fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  pw.Widget _buildRoPartyDetails(ReleaseOrderModel ro) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _infoBox('CLIENT DETAILS', [
            _infoRow('Name', ro.partyName),
          ]),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: _infoBox('PUBLICATION DETAILS', [
            _infoRow('Media House', ro.mediaHouseName),
            _infoRow('Agency', ro.agencyName),
            _infoRow('Pub. Date', _dateFmt.format(ro.publicationDate)),
          ]),
        ),
      ],
    );
  }

  pw.Widget _buildRoAdDetails(ReleaseOrderModel ro) {
    return _infoBox('ADVERTISEMENT DETAILS', [
      _infoRow('Category', ro.category),
      _infoRow('Ad Size', '${ro.adWidth} × ${ro.adHeight} ${ro.adUnit}'),
      _infoRow('Rate', '₹ ${_currFmt.format(ro.rate)} per ${ro.adUnit}'),
    ]);
  }

  pw.Widget _buildRoFinancials(ReleaseOrderModel ro) {
    final rows = [
      _tableRow('Amount', ro.amount, bold: false),
      _tableRow('Trade Discount (15%)', -ro.tradeDiscount, bold: false, isNegative: true),
      _tableRow('Taxable Amount', ro.taxableAmount, bold: false),
      if (ro.isGst) ...[
        _tableRow('CGST (${ro.gstPercent / 2}%)', ro.cgst, bold: false),
        _tableRow('SGST (${ro.gstPercent / 2}%)', ro.sgst, bold: false),
      ],
      _tableRow('Net Payable', ro.netPayable, bold: true),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(children: rows),
    );
  }

  pw.Widget _tableRow(String label, double amount,
      {bool bold = false, bool isNegative = false}) {
    final style = bold
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)
        : const pw.TextStyle(fontSize: 10);
    final bg = bold ? PdfColors.blue50 : PdfColors.white;
    final amtStr = isNegative
        ? '(₹ ${_currFmt.format(amount.abs())})'
        : '₹ ${_currFmt.format(amount)}';

    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(amtStr, style: style),
        ],
      ),
    );
  }

  pw.Widget _buildRoFooter(pw.ImageProvider? sign, pw.ImageProvider? stamp) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Terms & Conditions:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('1. This RO is valid for one-time publication only.',
              style: const pw.TextStyle(fontSize: 8)),
          pw.Text('2. Payment due within 30 days of publication.',
              style: const pw.TextStyle(fontSize: 8)),
          pw.Text('3. Subject to jurisdiction of local courts.',
              style: const pw.TextStyle(fontSize: 8)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (sign != null) pw.Image(sign, width: 60, height: 40),
          if (stamp != null) pw.Image(stamp, width: 60, height: 60),
          pw.Text('Authorised Signature',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(AppConstants.companyName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        ]),
      ],
    );
  }

  // ── Invoice PDF ────────────────────────────────────────
  Future<Uint8List> generateInvoicePdf(
    InvoiceModel invoice, {
    Uint8List? logoBytes,
    Uint8List? stampBytes,
    Uint8List? signatureBytes,
  }) async {
    final doc = pw.Document();
    final logoImg = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final stampImg = stampBytes != null ? pw.MemoryImage(stampBytes) : null;
    final signImg = signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInvoiceHeader(invoice, logoImg),
          pw.SizedBox(height: 16),
          _buildInvoiceParties(invoice),
          pw.SizedBox(height: 16),
          _buildInvoiceTable(invoice),
          pw.SizedBox(height: 16),
          _buildInvoiceSummary(invoice),
          pw.SizedBox(height: 24),
          _buildInvoiceFooter(signImg, stampImg),
        ],
      ),
    ));

    return doc.save();
  }

  pw.Widget _buildInvoiceHeader(InvoiceModel inv, pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(AppConstants.companyName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(AppConstants.companyAddress,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text('GSTIN: ${AppConstants.companyGstin}',
              style: const pw.TextStyle(fontSize: 9)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          if (logo != null) pw.Image(logo, width: 70, height: 70),
          pw.Text(inv.isGstInvoice ? 'TAX INVOICE' : 'INVOICE',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800)),
          pw.Text('No: ${inv.invoiceNumber}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('Date: ${_dateFmt.format(inv.invoiceDate)}',
              style: const pw.TextStyle(fontSize: 10)),
        ]),
      ],
    );
  }

  pw.Widget _buildInvoiceParties(InvoiceModel inv) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _infoBox('BILL TO', [
            _infoRow('Name', inv.partyName),
            if (inv.partyAddress != null) _infoRow('Address', inv.partyAddress!),
            if (inv.partyGstin != null) _infoRow('GSTIN', inv.partyGstin!),
          ]),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: _infoBox('AD DETAILS', [
            _infoRow('Media House', inv.mediaHouseName),
            _infoRow('RO Number', inv.roNumber),
            _infoRow('Pub. Date', _dateFmt.format(inv.publicationDate)),
          ]),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceTable(InvoiceModel inv) {
    const headerStyle =
        pw.TextStyle(color: PdfColors.white, fontSize: 10);
    final headers = ['Description', 'Amount (₹)'];
    final rows = [
      ['Advertisement Amount', _currFmt.format(inv.amount)],
      ['Less: Trade Discount (15%)', '(${_currFmt.format(inv.tradeDiscount)})'],
      ['Taxable Amount', _currFmt.format(inv.taxableAmount)],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                  ))
              .toList(),
        ),
        ...rows.map((r) => pw.TableRow(
              children: r
                  .map((c) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(c, style: const pw.TextStyle(fontSize: 10)),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  pw.Widget _buildInvoiceSummary(InvoiceModel inv) {
    final items = <pw.Widget>[
      _tableRow('Taxable Amount', inv.taxableAmount),
      if (inv.isGstInvoice && inv.gstType != 'none') ...[
        _tableRow('CGST', inv.cgst),
        _tableRow('SGST', inv.sgst),
      ],
      _tableRow('Total Amount', inv.totalAmount, bold: true),
      _tableRow('Amount Paid', inv.amountPaid),
      _tableRow('Balance Due', inv.balanceAmount, bold: true),
    ];

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 280,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(children: items),
      ),
    );
  }

  pw.Widget _buildInvoiceFooter(pw.ImageProvider? sign, pw.ImageProvider? stamp) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Bank Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Bank: Your Bank Name', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('Account No: XXXXXXXXXX', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('IFSC: XXXXXXX', style: const pw.TextStyle(fontSize: 8)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (sign != null) pw.Image(sign, width: 60, height: 40),
          if (stamp != null) pw.Image(stamp, width: 60, height: 60),
          pw.Text('Authorised Signatory',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(AppConstants.companyName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        ]),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────
  pw.Widget _infoBox(String title, List<pw.Widget> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.blue800)),
          pw.SizedBox(height: 4),
          ...rows,
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text('$label :',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  // ── Save & Share ───────────────────────────────────────
  Future<File> savePdfToTemp(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> sharePdf(Uint8List bytes, String fileName, String subject) async {
    final file = await savePdfToTemp(bytes, fileName);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: subject,
    );
  }

  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> previewPdf(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'preview.pdf');
  }
}
