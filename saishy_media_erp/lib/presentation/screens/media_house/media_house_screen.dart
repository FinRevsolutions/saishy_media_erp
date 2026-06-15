import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/media_house_model.dart';
import '../../../data/models/media_rate_card_model.dart';
import '../../../data/providers/media_house_provider.dart';
import '../../../data/providers/rate_card_provider.dart';
import '../../widgets/common_widgets.dart';

// ── Media House List ───────────────────────────────────
class MediaHouseListScreen extends ConsumerStatefulWidget {
  const MediaHouseListScreen({super.key});
  @override
  ConsumerState<MediaHouseListScreen> createState() => _MediaHouseListScreenState();
}

class _MediaHouseListScreenState extends ConsumerState<MediaHouseListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mhAsync = ref.watch(mediaHouseProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Media Houses'), actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.read(mediaHouseProvider.notifier).refresh()),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search media houses...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: mhAsync.when(
              loading: () => const LoadingWidget(message: 'Loading media houses...'),
              error: (e, _) => EmptyStateWidget(title: 'Error', subtitle: e.toString(), icon: Icons.error_outline_rounded),
              data: (list) {
                final filtered = _search.isEmpty ? list : list.where((m) =>
                  m.name.toLowerCase().contains(_search.toLowerCase()) ||
                  (m.edition?.toLowerCase().contains(_search.toLowerCase()) ?? false)).toList();
                if (filtered.isEmpty) return EmptyStateWidget(
                  title: 'No Media Houses', subtitle: 'Add your first media house',
                  icon: Icons.newspaper_outlined,
                  actionLabel: 'Add Media House',
                  onAction: () => context.push(RouteConstants.mediaHouseCreate),
                );
                return RefreshIndicator(
                  onRefresh: () => ref.read(mediaHouseProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _MediaHouseTile(mh: filtered[i])
                        .animate().fadeIn(delay: Duration(milliseconds: i * 40), duration: 300.ms),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.mediaHouseCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Media House'),
      ),
    );
  }
}

class _MediaHouseTile extends ConsumerWidget {
  final MediaHouseModel mh;
  const _MediaHouseTile({required this.mh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateCards = ref.watch(rateCardsForMediaHouseProvider(mh.id));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 20),
            ),
            title: Text(mh.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                if (mh.edition != null)
                  Text('Edition: ${mh.edition}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                Row(children: [
                  const Icon(Icons.phone_outlined, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(mh.mobile ?? '-', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text('GST ${mh.gstPercentage}%', style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
              color: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (action) {
                if (action == 'edit') context.push(RouteConstants.mediaHouseEdit, extra: mh);
                if (action == 'rates') context.push(RouteConstants.rateCards, extra: mh);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined, size: 18), title: Text('Edit'), dense: true, contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(value: 'rates', child: ListTile(leading: Icon(Icons.price_change_outlined, size: 18, color: AppColors.accent), title: Text('Manage Rate Card'), dense: true, contentPadding: EdgeInsets.zero)),
              ],
            ),
          ),
          // Rate card chips
          if (rateCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6, runSpacing: 4,
                children: rateCards.map((rc) => Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text('${rc.rateType}: ${AppFormatters.currency(rc.ratePerUnit)}/${rc.unit}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Media House Form ───────────────────────────────────
class MediaHouseFormScreen extends ConsumerStatefulWidget {
  final MediaHouseModel? mediaHouse;
  const MediaHouseFormScreen({super.key, this.mediaHouse});

  @override
  ConsumerState<MediaHouseFormScreen> createState() => _MediaHouseFormScreenState();
}

class _MediaHouseFormScreenState extends ConsumerState<MediaHouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _edition, _language, _contactPerson, _mobile, _email, _address, _notes;
  late double _gstPercentage;
  bool _loading = false;

  bool get isEdit => widget.mediaHouse != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mediaHouse;
    _name          = TextEditingController(text: m?.name ?? '');
    _edition       = TextEditingController(text: m?.edition ?? '');
    _language      = TextEditingController(text: m?.language ?? '');
    _contactPerson = TextEditingController(text: m?.contactPerson ?? '');
    _mobile        = TextEditingController(text: m?.mobile ?? '');
    _email         = TextEditingController(text: m?.email ?? '');
    _address       = TextEditingController(text: m?.address ?? '');
    _notes         = TextEditingController(text: m?.notes ?? '');
    _gstPercentage = m?.gstPercentage ?? 5.0;
  }

  @override
  void dispose() {
    for (final c in [_name, _edition, _language, _contactPerson, _mobile, _email, _address, _notes]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final mh = MediaHouseModel(
      id: widget.mediaHouse?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      edition: _edition.text.trim().isEmpty ? null : _edition.text.trim(),
      language: _language.text.trim().isEmpty ? null : _language.text.trim(),
      contactPerson: _contactPerson.text.trim().isEmpty ? null : _contactPerson.text.trim(),
      mobile: _mobile.text.trim().isEmpty ? null : _mobile.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      gstPercentage: _gstPercentage,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.mediaHouse?.createdAt,
    );

    final notifier = ref.read(mediaHouseProvider.notifier);
    final ok = isEdit ? await notifier.update(mh) : await notifier.create(mh);
    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit ? 'Media house updated' : 'Media house added'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (!isEdit) {
        // Navigate to rate card after creation
        final saved = ref.read(mediaHouseProvider).valueOrNull?.firstWhere((m) => m.name == mh.name, orElse: () => mh);
        if (mounted) context.pushReplacement(RouteConstants.rateCards, extra: saved);
      } else {
        if (mounted) context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Media House' : 'Add Media House'),
        actions: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Publication Details', [
              _field(_name, 'Media House Name *', Icons.newspaper_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              _field(_edition, 'Edition / Edition Name', Icons.local_newspaper_outlined),
              _field(_language, 'Language', Icons.language_rounded),
            ]),
            const SizedBox(height: 16),
            _buildSection('Contact', [
              _field(_contactPerson, 'Contact Person', Icons.person_outline_rounded),
              _field(_mobile, 'Mobile', Icons.phone_outlined, keyboard: TextInputType.phone),
              _field(_email, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
              _multilineField(_address, 'Address', Icons.location_on_outlined),
            ]),
            const SizedBox(height: 16),
            _buildSection('GST Configuration', [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.percent_rounded, color: AppColors.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text('GST: ${_gstPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('0%', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Expanded(
                          child: Slider(
                            value: _gstPercentage,
                            min: 0, max: 28,
                            divisions: 7,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _gstPercentage = v),
                          ),
                        ),
                        const Text('28%', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                    const Text('Common: 0%, 5%, 12%, 18%', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Notes', [_multilineField(_notes, 'Notes', Icons.notes_rounded)]),
            if (!isEdit) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(children: const [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'After saving, you\'ll be redirected to configure the Rate Card for this media house.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
        const Divider(color: AppColors.borderDark, height: 1),
        ...children,
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextFormField(controller: ctrl, keyboardType: keyboard, validator: validator, style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none)),
    );
  }

  Widget _multilineField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextFormField(controller: ctrl, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(labelText: label, prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 44), child: Icon(icon, size: 18)), alignLabelWithHint: true, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none)),
    );
  }
}
