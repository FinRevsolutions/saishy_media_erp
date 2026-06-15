import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/release_order_model.dart';
import '../../../data/models/media_rate_card_model.dart';
import '../../../data/providers/release_order_provider.dart';
import '../../../data/providers/party_provider.dart';
import '../../../data/providers/media_house_provider.dart';
import '../../../data/providers/rate_card_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

// ── RO List ────────────────────────────────────────────
class ReleaseOrderListScreen extends ConsumerStatefulWidget {
  const ReleaseOrderListScreen({super.key});
  @override
  ConsumerState<ReleaseOrderListScreen> createState() => _ROListState();
}

class _ROListState extends ConsumerState<ReleaseOrderListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All';

  static const _statuses = ['All', 'Draft', 'Sent', 'Accepted', 'Published', 'Billed', 'Paid'];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rosAsync = ref.watch(releaseOrderProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Release Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.read(releaseOrderProvider.notifier).refresh()),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search ROs...', prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }) : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // Status filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              itemCount: _statuses.length,
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final selected = s == _statusFilter;
                return GestureDetector(
                  onTap: () => setState(() => _statusFilter = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.borderDark),
                    ),
                    child: Text(s, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: rosAsync.when(
              loading: () => const LoadingWidget(message: 'Loading release orders...'),
              error: (e, _) => EmptyStateWidget(title: 'Error', subtitle: e.toString(), icon: Icons.error_outline_rounded),
              data: (ros) {
                var filtered = ros;
                if (_statusFilter != 'All') filtered = filtered.where((r) => r.status == _statusFilter).toList();
                if (_search.isNotEmpty) filtered = filtered.where((r) =>
                  r.roNumber.toLowerCase().contains(_search.toLowerCase()) ||
                  r.partyName.toLowerCase().contains(_search.toLowerCase()) ||
                  r.mediaHouseName.toLowerCase().contains(_search.toLowerCase())).toList();

                if (filtered.isEmpty) return EmptyStateWidget(
                  title: 'No Release Orders', subtitle: 'Create a new RO using the + button',
                  icon: Icons.article_outlined, actionLabel: 'Create RO',
                  onAction: () => context.push(RouteConstants.roCreate),
                );
                return RefreshIndicator(
                  onRefresh: () => ref.read(releaseOrderProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ROTile(ro: filtered[i])
                        .animate().fadeIn(delay: Duration(milliseconds: i * 30), duration: 300.ms),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.roCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create RO'),
      ),
    );
  }
}

class _ROTile extends StatelessWidget {
  final ReleaseOrderModel ro;
  const _ROTile({required this.ro});

  @override
  Widget build(BuildContext context) {
    final pubDate = DateFormat('dd MMM yyyy').format(ro.publicationDate);
    return GestureDetector(
      onTap: () => context.push(RouteConstants.roDetail, extra: ro),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ro.isDraft ? AppColors.warning.withOpacity(0.3) : AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(ro.roNumber, style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700))),
                StatusChip(label: ro.status),
                if (ro.isDraft) ...[
                  const SizedBox(width: 6),
                  const StatusChip(label: 'Draft'),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.business_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text(ro.partyName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.newspaper_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text('${ro.mediaHouseName} • ${ro.agencyName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('Pub: $pubDate', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const Spacer(),
              Text(AppFormatters.currency(ro.netPayable),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── RO Form ────────────────────────────────────────────
class ReleaseOrderFormScreen extends ConsumerStatefulWidget {
  final ReleaseOrderModel? ro;
  const ReleaseOrderFormScreen({super.key, this.ro});

  @override
  ConsumerState<ReleaseOrderFormScreen> createState() => _ROFormState();
}

class _ROFormState extends ConsumerState<ReleaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selections
  String? _partyId, _partyName;
  String? _mediaHouseId, _mediaHouseName;
  String  _agencyName = '';
  String  _category   = 'Display';
  String  _rateType   = 'Black & White';
  String  _gstType    = 'none';
  String  _adUnit     = 'col×cm';
  bool    _isDraft    = false;
  bool    _loading    = false;

  DateTime _date           = DateTime.now();
  DateTime _publicationDate = DateTime.now().add(const Duration(days: 3));

  final _adWidthCtrl  = TextEditingController();
  final _adHeightCtrl = TextEditingController();
  final _rateCtrl     = TextEditingController();
  final _notesCtrl    = TextEditingController();

  String  _roNumber = '';

  // Computed
  double get adW      => double.tryParse(_adWidthCtrl.text)  ?? 0;
  double get adH      => double.tryParse(_adHeightCtrl.text) ?? 0;
  double get rate     => double.tryParse(_rateCtrl.text)     ?? 0;
  double get area     => adW * adH;
  double get amount   => area * rate;
  double get discount => amount * 0.15;
  double get taxable  => amount - discount;
  double get gstPct   => _gstType == 'gst5' ? 5 : _gstType == 'gst18' ? 18 : 0;
  double get gstAmt   => taxable * gstPct / 100;
  double get net      => taxable + gstAmt;

  bool get isEdit => widget.ro != null;

  @override
  void initState() {
    super.initState();
    _initFromRO();
    _loadRONumber();
  }

  void _initFromRO() {
    final ro = widget.ro;
    if (ro == null) return;
    _partyId        = ro.partyId;
    _partyName      = ro.partyName;
    _mediaHouseId   = ro.mediaHouseId;
    _mediaHouseName = ro.mediaHouseName;
    _agencyName     = ro.agencyName;
    _category       = ro.category;
    _rateType       = ro.rateType;
    _gstType        = ro.gstType;
    _adUnit         = ro.adUnit;
    _isDraft        = ro.isDraft;
    _date           = ro.date;
    _publicationDate = ro.publicationDate;
    _adWidthCtrl.text  = ro.adWidth.toString();
    _adHeightCtrl.text = ro.adHeight.toString();
    _rateCtrl.text     = ro.rate.toString();
    _notesCtrl.text    = ro.notes ?? '';
    _roNumber          = ro.roNumber;
  }

  Future<void> _loadRONumber() async {
    if (isEdit) return;
    final num = await ref.read(releaseOrderProvider.notifier).getNextNumber();
    setState(() => _roNumber = num);
  }

  void _autoFillRate() {
    if (_mediaHouseId == null) return;
    final rate = ref.read(autoFillRateProvider((
      mediaHouseId: _mediaHouseId!,
      rateType: _rateType,
    )));
    if (rate != null) {
      _rateCtrl.text = rate.toStringAsFixed(2);
      final unit = ref.read(autoFillUnitProvider(_mediaHouseId!));
      if (unit != null) setState(() => _adUnit = unit);
    }
  }

  Future<void> _save({bool draft = false}) async {
    if (!draft && !(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _isDraft = draft; });

    final user = ref.read(currentUserProvider);
    final ro = ReleaseOrderModel(
      roNumber: _roNumber.isEmpty ? const Uuid().v4() : _roNumber,
      date: _date, partyId: _partyId ?? '', partyName: _partyName ?? '',
      mediaHouseId: _mediaHouseId ?? '', mediaHouseName: _mediaHouseName ?? '',
      agencyName: _agencyName,
      publicationDate: _publicationDate,
      category: _category, adWidth: adW, adHeight: adH, adUnit: _adUnit,
      rate: rate, rateType: _rateType, gstType: _gstType,
      amount: amount, tradeDiscount: discount, taxableAmount: taxable,
      gstAmount: gstAmt, netPayable: net,
      status: draft ? 'Draft' : (isEdit ? widget.ro!.status : 'Sent'),
      createdBy: user?.fullName ?? 'Unknown',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isDraft: draft, createdAt: widget.ro?.createdAt,
    );

    final notifier = ref.read(releaseOrderProvider.notifier);
    final ok = isEdit ? await notifier.update(ro) : await notifier.create(ro);
    setState(() => _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? (draft ? 'Saved as draft' : (isEdit ? 'RO updated' : 'RO created: ${ro.roNumber}')) : 'Failed to save'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    if (ok) context.pop();
  }

  @override
  void dispose() {
    _adWidthCtrl.dispose(); _adHeightCtrl.dispose();
    _rateCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parties     = ref.watch(partyProvider).valueOrNull ?? [];
    final mediaHouses = ref.watch(mediaHouseProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit RO' : 'Create Release Order'),
        actions: [
          if (!isEdit)
            TextButton(
              onPressed: _loading ? null : () => _save(draft: true),
              child: const Text('Draft', style: TextStyle(color: AppColors.warning)),
            ),
          if (_loading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton(onPressed: () => _save(), child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // RO Number
            _buildCard([
              ListTile(
                leading: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                title: const Text('RO Number', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                subtitle: Text(_roNumber.isEmpty ? 'Generating...' : _roNumber,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(DateFormat('dd MMM yy').format(_date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                ]),
              ),
            ]),
            const SizedBox(height: 12),

            // Client
            _buildCard([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('CLIENT', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: DropdownButtonFormField<String>(
                  value: _partyId,
                  dropdownColor: AppColors.surfaceDark,
                  validator: (v) => v == null ? 'Select a client' : null,
                  decoration: const InputDecoration(labelText: 'Select Client *', prefixIcon: Icon(Icons.people_outline_rounded, size: 18), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                  items: parties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)))).toList(),
                  onChanged: (v) {
                    final p = parties.firstWhere((p) => p.id == v);
                    setState(() { _partyId = v; _partyName = p.name; });
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Media House
            _buildCard([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('MEDIA HOUSE', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: DropdownButtonFormField<String>(
                  value: _mediaHouseId,
                  dropdownColor: AppColors.surfaceDark,
                  validator: (v) => v == null ? 'Select a media house' : null,
                  decoration: const InputDecoration(labelText: 'Select Media House *', prefixIcon: Icon(Icons.newspaper_outlined, size: 18), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                  items: mediaHouses.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final m = mediaHouses.firstWhere((m) => m.id == v);
                    final agencyName = ref.read(agencyForMediaHouseProvider(v));
                    setState(() {
                      _mediaHouseId   = v;
                      _mediaHouseName = m.name;
                      _agencyName     = agencyName.isNotEmpty ? agencyName : m.name;
                    });
                    _autoFillRate();
                  },
                ),
              ),
              if (_agencyName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(children: [
                    const Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text('Agency: $_agencyName', style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                  ]),
                ),
            ]),
            const SizedBox(height: 12),

            // Publication date
            _buildCard([
              ListTile(
                leading: const Icon(Icons.event_rounded, color: AppColors.primary),
                title: const Text('Publication Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                subtitle: Text(DateFormat('EEEE, dd MMMM yyyy').format(_publicationDate),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _publicationDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setState(() => _publicationDate = d);
                },
                trailing: const Icon(Icons.edit_calendar_rounded, color: AppColors.textMuted, size: 18),
              ),
            ]),
            const SizedBox(height: 12),

            // Ad Details
            _buildCard([
              Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text('ADVERTISEMENT', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
              const Divider(color: AppColors.borderDark, height: 1),
              _fieldRow('Category', _buildCategoryDropdown()),
              _fieldRow('Rate Type', _buildRateTypeDropdown()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  Expanded(child: TextFormField(controller: _adWidthCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null, onChanged: (_) => setState(() {}), style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Width *', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none))),
                  const Text('×', style: TextStyle(color: AppColors.textMuted)),
                  Expanded(child: TextFormField(controller: _adHeightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null, onChanged: (_) => setState(() {}), style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Height *', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none))),
                  const SizedBox(width: 8),
                  Text(_adUnit, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: TextFormField(controller: _rateCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter rate' : null, onChanged: (_) => setState(() {}), style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(labelText: 'Rate per $_adUnit *', prefixText: '₹ ', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                    suffix: TextButton(onPressed: _autoFillRate, child: const Text('Auto-fill', style: TextStyle(fontSize: 11))))),
              ),
              _fieldRow('GST', _buildGstDropdown()),
            ]),
            const SizedBox(height: 12),

            // Financial summary
            if (amount > 0) _buildFinancials(),
            const SizedBox(height: 12),

            // Notes
            _buildCard([
              Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextFormField(controller: _notesCtrl, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Notes / Special Instructions', prefixIcon: Padding(padding: EdgeInsets.only(bottom: 44), child: Icon(Icons.notes_rounded, size: 18)), alignLabelWithHint: true, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none))),
            ]),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderDark)),
    child: Column(children: children),
  );

  Widget _fieldRow(String label, Widget field) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
    child: field,
  );

  Widget _buildCategoryDropdown() {
    const cats = ['Display', 'Classified', 'Tender', 'Public Notice', 'Obituary', 'Other'];
    return DropdownButtonFormField<String>(
      value: _category, dropdownColor: AppColors.surfaceDark,
      decoration: const InputDecoration(labelText: 'Category', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
      items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)))).toList(),
      onChanged: (v) => setState(() => _category = v ?? _category),
    );
  }

  Widget _buildRateTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _rateType, dropdownColor: AppColors.surfaceDark,
      decoration: const InputDecoration(labelText: 'Rate Type', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
      items: MediaRateCardModel.rateTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)))).toList(),
      onChanged: (v) { setState(() => _rateType = v ?? _rateType); _autoFillRate(); },
    );
  }

  Widget _buildGstDropdown() {
    return DropdownButtonFormField<String>(
      value: _gstType, dropdownColor: AppColors.surfaceDark,
      decoration: const InputDecoration(labelText: 'GST', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
      items: const [
        DropdownMenuItem(value: 'none',  child: Text('No GST',  style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
        DropdownMenuItem(value: 'gst5',  child: Text('5% GST',  style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
        DropdownMenuItem(value: 'gst18', child: Text('18% GST', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
      ],
      onChanged: (v) => setState(() => _gstType = v ?? _gstType),
    );
  }

  Widget _buildFinancials() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.1), AppColors.cardDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FINANCIAL SUMMARY', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _finRow('Ad Area', '${area.toStringAsFixed(2)} $_adUnit'),
          _finRow('Amount', AppFormatters.currency(amount)),
          _finRow('Trade Discount (15%)', '(${AppFormatters.currency(discount)})'),
          _finRow('Taxable Amount', AppFormatters.currency(taxable)),
          if (gstPct > 0) ...[
            _finRow('CGST (${gstPct / 2}%)', AppFormatters.currency(gstAmt / 2)),
            _finRow('SGST (${gstPct / 2}%)', AppFormatters.currency(gstAmt / 2)),
          ],
          const Divider(color: AppColors.borderDark, height: 20),
          _finRow('NET PAYABLE', AppFormatters.currency(net), bold: true, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _finRow(String label, String value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      color: color ?? (bold ? AppColors.textPrimary : AppColors.textSecondary),
      fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ]),
    );
  }
}
