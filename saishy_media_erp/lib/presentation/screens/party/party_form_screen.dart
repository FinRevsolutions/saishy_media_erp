import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/party_model.dart';
import '../../../data/providers/party_provider.dart';

class PartyFormScreen extends ConsumerStatefulWidget {
  final PartyModel? party;
  const PartyFormScreen({super.key, this.party});

  @override
  ConsumerState<PartyFormScreen> createState() => _PartyFormScreenState();
}

class _PartyFormScreenState extends ConsumerState<PartyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _mobile, _email, _gstin, _contactPerson, _state, _stateCode, _notes;
  bool _gstApplicable = false;
  bool _loading = false;

  bool get isEdit => widget.party != null;

  @override
  void initState() {
    super.initState();
    final p = widget.party;
    _name          = TextEditingController(text: p?.name ?? '');
    _address       = TextEditingController(text: p?.address ?? '');
    _mobile        = TextEditingController(text: p?.mobile ?? '');
    _email         = TextEditingController(text: p?.email ?? '');
    _gstin         = TextEditingController(text: p?.gstin ?? '');
    _contactPerson = TextEditingController(text: p?.contactPerson ?? '');
    _state         = TextEditingController(text: p?.state ?? '');
    _stateCode     = TextEditingController(text: p?.stateCode ?? '');
    _notes         = TextEditingController(text: p?.notes ?? '');
    _gstApplicable = p?.gstApplicable ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _mobile, _email, _gstin, _contactPerson, _state, _stateCode, _notes]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final party = PartyModel(
      id: widget.party?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      address: _address.text.trim(),
      mobile: _mobile.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      gstApplicable: _gstApplicable,
      gstin: _gstApplicable ? _gstin.text.trim() : null,
      contactPerson: _contactPerson.text.trim().isEmpty ? null : _contactPerson.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      stateCode: _stateCode.text.trim().isEmpty ? null : _stateCode.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.party?.createdAt,
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(partyProvider.notifier);
    final ok = isEdit ? await notifier.update(party) : await notifier.create(party);
    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit ? 'Client updated' : 'Client added'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to save. Try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Client' : 'Add Client'),
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
            _buildSection('Basic Information', [
              _field(_name, 'Party Name *', Icons.business_rounded, validator: AppValidators.required),
              _field(_mobile, 'Mobile *', Icons.phone_outlined, keyboard: TextInputType.phone, validator: AppValidators.mobile),
              _field(_email, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
              _field(_contactPerson, 'Contact Person', Icons.person_outline_rounded),
            ]),
            const SizedBox(height: 16),
            _buildSection('Address', [
              _multilineField(_address, 'Address', Icons.location_on_outlined),
              _field(_state, 'State', Icons.map_outlined),
              _field(_stateCode, 'State Code', Icons.code_rounded, keyboard: TextInputType.number),
            ]),
            const SizedBox(height: 16),
            _buildSection('GST Details', [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_outlined, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('GST Applicable', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    ),
                    Switch(
                      value: _gstApplicable,
                      onChanged: (v) => setState(() => _gstApplicable = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              if (_gstApplicable)
                _field(_gstin, 'GSTIN', Icons.numbers_rounded,
                  validator: (v) => _gstApplicable ? AppValidators.gstin(v) : null),
            ]),
            const SizedBox(height: 16),
            _buildSection('Additional', [
              _multilineField(_notes, 'Notes', Icons.notes_rounded),
            ]),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _multilineField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextFormField(
        controller: ctrl, maxLines: 3,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label, prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 44), child: Icon(icon, size: 18)),
          alignLabelWithHint: true,
          border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
