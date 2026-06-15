import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/providers/invoice_payment_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

// ── Invoice List ───────────────────────────────────────
class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});
  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListState();
}

class _InvoiceListState extends ConsumerState<InvoiceListScreen> {
  String _search = '';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final invAsync = ref.watch(invoiceProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.read(invoiceProvider.notifier).refresh())],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Search invoices...', prefixIcon: Icon(Icons.search_rounded, size: 20), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onChanged: (v) => setState(() => _search = v)),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              children: ['All', 'Pending', 'Partial', 'Paid'].map((s) {
                final selected = s == _statusFilter;
                return GestureDetector(
                  onTap: () => setState(() => _statusFilter = s),
                  child: Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppColors.primary : AppColors.borderDark)),
                    child: Text(s, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500))),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: invAsync.when(
              loading: () => const LoadingWidget(message: 'Loading invoices...'),
              error: (e, _) => EmptyStateWidget(title: 'Error', subtitle: e.toString(), icon: Icons.error_outline_rounded),
              data: (invs) {
                var filtered = invs;
                if (_statusFilter != 'All') filtered = filtered.where((i) => i.status == _statusFilter).toList();
                if (_search.isNotEmpty) filtered = filtered.where((i) =>
                  i.invoiceNumber.toLowerCase().contains(_search.toLowerCase()) ||
                  i.partyName.toLowerCase().contains(_search.toLowerCase()) ||
                  i.roNumber.toLowerCase().contains(_search.toLowerCase())).toList();
                if (filtered.isEmpty) return EmptyStateWidget(title: 'No Invoices', subtitle: 'Invoices auto-generate when ROs are Published', icon: Icons.receipt_long_outlined);
                return RefreshIndicator(
                  onRefresh: () => ref.read(invoiceProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _InvoiceTile(invoice: filtered[i])
                        .animate().fadeIn(delay: Duration(milliseconds: i * 30), duration: 300.ms),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final invDate  = DateFormat('dd MMM yy').format(invoice.invoiceDate);
    final balance  = invoice.balanceAmount;
    return GestureDetector(
      onTap: () => context.push(RouteConstants.invoiceDetail, extra: invoice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderDark)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(invoice.invoiceNumber, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700))),
              StatusChip(label: invoice.status),
            ]),
            const SizedBox(height: 4),
            Text(invoice.partyName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              Text('RO: ${invoice.roNumber}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const Spacer(),
              Text(invDate, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Text('Total: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(AppFormatters.currency(invoice.totalAmount), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (balance > 0) ...[
                const Text('Due: ', style: TextStyle(color: AppColors.error, fontSize: 12)),
                Text(AppFormatters.currency(balance), style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w700)),
              ] else ...[
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                const SizedBox(width: 4),
                const Text('Paid', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Invoice Detail ─────────────────────────────────────
class InvoiceDetailScreen extends ConsumerWidget {
  final InvoiceModel invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentProvider).valueOrNull?.where((p) => p.invoiceNumber == invoice.invoiceNumber).toList() ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(icon: const Icon(Icons.print_outlined), onPressed: () => _printInvoice(context, invoice)),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () => _shareInvoice(context, invoice)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(invoice),
          const SizedBox(height: 16),
          _buildPartySection(invoice),
          const SizedBox(height: 16),
          _buildAmountBreakdown(invoice),
          const SizedBox(height: 16),
          _buildPaymentHistory(payments),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: invoice.status != 'Paid'
          ? FloatingActionButton.extended(
              onPressed: () => context.push(RouteConstants.paymentCreate, extra: invoice),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record Payment'),
              backgroundColor: AppColors.success,
            )
          : null,
    );
  }

  void _printInvoice(BuildContext ctx, InvoiceModel inv) {
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('PDF generation: Open from Documents'), behavior: SnackBarBehavior.floating));
  }

  void _shareInvoice(BuildContext ctx, InvoiceModel inv) {
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Share via WhatsApp: Generate PDF first'), behavior: SnackBarBehavior.floating));
  }

  Widget _buildHeader(InvoiceModel inv) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.12), AppColors.cardDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(inv.isGstInvoice ? 'TAX INVOICE' : 'INVOICE', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1))),
            StatusChip(label: inv.status),
          ]),
          const SizedBox(height: 8),
          Text(inv.invoiceNumber, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(children: [
            Text('RO: ${inv.roNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(width: 16),
            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(DateFormat('dd MMM yyyy').format(inv.invoiceDate), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('NET PAYABLE', style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.5)),
                Text(AppFormatters.currency(inv.totalAmount), style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('OUTSTANDING', style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.5)),
                Text(AppFormatters.currency(inv.balanceAmount),
                  style: TextStyle(color: inv.balanceAmount > 0 ? AppColors.error : AppColors.success, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPartySection(InvoiceModel inv) {
    return ErpCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('BILL TO', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(inv.partyName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        if (inv.partyAddress != null) Text(inv.partyAddress!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        if (inv.partyGstin != null && inv.partyGstin!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('GSTIN: ${inv.partyGstin}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
        const Divider(color: AppColors.borderDark, height: 20),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Media House', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            Text(inv.mediaHouseName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Publication Date', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            Text(DateFormat('dd MMM yyyy').format(inv.publicationDate), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
        ]),
      ]),
    );
  }

  Widget _buildAmountBreakdown(InvoiceModel inv) {
    return ErpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AMOUNT BREAKDOWN', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _amtRow('Advertisement Amount', inv.amount),
          _amtRow('Trade Discount (15%)', -inv.tradeDiscount),
          _amtRow('Taxable Amount', inv.taxableAmount),
          if (inv.isGstInvoice && inv.gstType != 'none') ...[
            const Divider(color: AppColors.borderDark, height: 16),
            _amtRow('CGST', inv.cgst),
            _amtRow('SGST', inv.sgst),
          ],
          const Divider(color: AppColors.borderDark, height: 16),
          _amtRow('TOTAL', inv.totalAmount, bold: true, color: AppColors.textPrimary),
          _amtRow('Amount Paid', inv.amountPaid, color: AppColors.success),
          _amtRow('Balance Due', inv.balanceAmount, bold: true, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _amtRow(String label, double value, {bool bold = false, Color? color}) {
    final isNeg = value < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontSize: bold ? 14 : 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w400))),
        Text('${isNeg ? "(" : ""}${AppFormatters.currency(value.abs())}${isNeg ? ")" : ""}',
          style: TextStyle(color: color ?? (bold ? AppColors.textPrimary : AppColors.textSecondary), fontSize: bold ? 14 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      ]),
    );
  }

  Widget _buildPaymentHistory(List<PaymentModel> payments) {
    if (payments.isEmpty) return const ErpCard(child: EmptyStateWidget(title: 'No Payments Recorded', icon: Icons.payment_outlined));
    return ErpCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PAYMENT HISTORY', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ...payments.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.check_rounded, color: AppColors.success, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppFormatters.currency(p.amountPaid), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${p.paymentMode} • ${DateFormat('dd MMM yyyy').format(p.paymentDate)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            StatusChip(label: p.status),
          ]),
        )),
      ]),
    );
  }
}

// ── Payment Form ───────────────────────────────────────
class PaymentFormScreen extends ConsumerStatefulWidget {
  final InvoiceModel invoice;
  const PaymentFormScreen({super.key, required this.invoice});
  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentFormScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _chequeCtrl = TextEditingController();
  final _bankCtrl   = TextEditingController();
  final _txnCtrl    = TextEditingController();
  final _notesCtrl  = TextEditingController();
  String _paymentMode = 'Bank Transfer';
  DateTime _paymentDate = DateTime.now();
  bool _loading = false;

  static const _modes = ['Bank Transfer', 'Cheque', 'Cash', 'UPI', 'NEFT', 'RTGS', 'IMPS'];

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.invoice.balanceAmount.toStringAsFixed(2);
  }

  @override
  void dispose() { _amountCtrl.dispose(); _chequeCtrl.dispose(); _bankCtrl.dispose(); _txnCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final user   = ref.read(currentUserProvider);
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    final payment = PaymentModel(
      id: const Uuid().v4(),
      invoiceNumber: widget.invoice.invoiceNumber,
      partyId: widget.invoice.partyId,
      partyName: widget.invoice.partyName,
      amountPaid: amount,
      invoiceTotal: widget.invoice.totalAmount,
      paymentDate: _paymentDate,
      paymentMode: _paymentMode,
      chequeNumber: _chequeCtrl.text.trim().isEmpty ? null : _chequeCtrl.text.trim(),
      bankName: _bankCtrl.text.trim().isEmpty ? null : _bankCtrl.text.trim(),
      transactionId: _txnCtrl.text.trim().isEmpty ? null : _txnCtrl.text.trim(),
      status: 'Received',
      receivedBy: user?.fullName ?? 'Unknown',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final ok = await ref.read(paymentProvider.notifier).create(payment);

    if (ok) {
      // Update invoice amount_paid
      final newPaid = widget.invoice.amountPaid + amount;
      final newStatus = newPaid >= widget.invoice.totalAmount ? 'Paid' : 'Partial';
      final updatedInvoice = widget.invoice.copyWith(amountPaid: newPaid, status: newStatus);
      await ref.read(invoiceProvider.notifier).update(updatedInvoice);
    }

    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Payment of ${AppFormatters.currency(amount)} recorded' : 'Failed to record payment'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    if (ok) { context.pop(); context.pop(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Record Payment'),
        actions: [
          if (_loading) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Form(key: _formKey, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Invoice info
          ErpCard(
            borderColor: AppColors.primary.withOpacity(0.2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Invoice: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text(widget.invoice.invoiceNumber, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(widget.invoice.partyName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text(AppFormatters.currency(widget.invoice.totalAmount), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ])),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  const Text('Paid', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text(AppFormatters.currency(widget.invoice.amountPaid), style: const TextStyle(color: AppColors.success, fontSize: 13)),
                ])),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Balance', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text(AppFormatters.currency(widget.invoice.balanceAmount), style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w700)),
                ])),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          ErpCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PAYMENT DETAILS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            TextFormField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) { final d = double.tryParse(v ?? ''); return d == null || d <= 0 ? 'Enter valid amount' : d > widget.invoice.balanceAmount + 0.01 ? 'Exceeds balance' : null; },
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Amount Paid *', prefixText: '₹ ', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
            ),
            DropdownButtonFormField<String>(value: _paymentMode, dropdownColor: AppColors.surfaceDark,
              decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.payment_outlined, size: 18), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
              items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _paymentMode = v ?? _paymentMode),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded, color: AppColors.textMuted, size: 18),
              title: const Text('Payment Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              subtitle: Text(DateFormat('dd MMMM yyyy').format(_paymentDate), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _paymentDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) setState(() => _paymentDate = d);
              },
            ),
          ])),
          const SizedBox(height: 12),

          if (_paymentMode == 'Cheque')
            ErpCard(child: Column(children: [
              TextFormField(controller: _chequeCtrl, style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Cheque Number', prefixIcon: Icon(Icons.receipt_outlined, size: 18), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none)),
              TextFormField(controller: _bankCtrl, style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Bank Name', prefixIcon: Icon(Icons.account_balance_outlined, size: 18), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none)),
            ])),

          if (_paymentMode == 'UPI' || _paymentMode == 'NEFT' || _paymentMode == 'RTGS' || _paymentMode == 'IMPS' || _paymentMode == 'Bank Transfer')
            ErpCard(child: TextFormField(controller: _txnCtrl, style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Transaction ID / UTR', prefixIcon: Icon(Icons.tag_rounded, size: 18), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none))),

          const SizedBox(height: 12),
          ErpCard(child: TextFormField(controller: _notesCtrl, maxLines: 2, style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Notes', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none))),
          const SizedBox(height: 80),
        ],
      )),
    );
  }
}
