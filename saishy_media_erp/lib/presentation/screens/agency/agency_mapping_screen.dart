import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/agency_mapping_model.dart';
import '../../../data/providers/agency_mapping_provider.dart';
import '../../../data/providers/media_house_provider.dart';
import '../../widgets/common_widgets.dart';

class AgencyMappingScreen extends ConsumerStatefulWidget {
  const AgencyMappingScreen({super.key});
  @override
  ConsumerState<AgencyMappingScreen> createState() => _AgencyMappingState();
}

class _AgencyMappingState extends ConsumerState<AgencyMappingScreen> {
  bool _showAddDialog = false;
  bool _adding = false;
  String? _selectedMHId;
  String? _selectedMHName;
  final _agencyCtrl = TextEditingController();

  @override
  void dispose() { _agencyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mappingsAsync   = ref.watch(agencyMappingProvider);
    final mediaHouses     = ref.watch(mediaHouseProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Agency Mappings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.read(agencyMappingProvider.notifier).refresh()),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.info.withOpacity(0.2))),
            child: Row(children: const [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
              SizedBox(width: 10),
              Expanded(child: Text('Map each Media House to the Agency Name used on Release Orders. When a media house is selected in an RO, the agency name auto-fills.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            ]),
          ),
          Expanded(
            child: mappingsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading mappings...'),
              error: (e, _) => EmptyStateWidget(title: 'Error', subtitle: e.toString(), icon: Icons.error_outline_rounded),
              data: (mappings) {
                if (mappings.isEmpty) return EmptyStateWidget(
                  title: 'No Mappings',
                  subtitle: 'Map media houses to agency names using the + button',
                  icon: Icons.swap_horiz_rounded,
                  actionLabel: 'Add Mapping',
                  onAction: () => _showAddSheet(context, mediaHouses),
                );
                return RefreshIndicator(
                  onRefresh: () => ref.read(agencyMappingProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: mappings.length,
                    itemBuilder: (_, i) => _MappingTile(mapping: mappings[i])
                        .animate().fadeIn(delay: Duration(milliseconds: i * 40), duration: 300.ms),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref.read(mediaHouseProvider).valueOrNull ?? []),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Mapping'),
      ),
    );
  }

  void _showAddSheet(BuildContext context, List mhs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderDark, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16)),
              const Text('Add Agency Mapping', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMHId,
                dropdownColor: AppColors.cardDark,
                decoration: const InputDecoration(labelText: 'Select Media House', prefixIcon: Icon(Icons.newspaper_outlined, size: 18)),
                items: mhs.map((m) => DropdownMenuItem<String>(value: m.id, child: Text(m.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)))).toList(),
                onChanged: (v) {
                  setModalState(() {
                    _selectedMHId   = v;
                    _selectedMHName = mhs.firstWhere((m) => m.id == v).name;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _agencyCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Agency Name',
                  hintText: 'e.g. R S Solutions',
                  prefixIcon: Icon(Icons.business_center_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              // Example hint
              Text('Example: ${_selectedMHName ?? 'Prabhat Khabar'} → ${_agencyCtrl.text.isEmpty ? 'R S Solutions' : _agencyCtrl.text}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _adding ? null : () async {
                    if (_selectedMHId == null || _agencyCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select media house and enter agency name'), behavior: SnackBarBehavior.floating));
                      return;
                    }
                    setModalState(() => _adding = true);
                    final mapping = AgencyMappingModel(
                      id: const Uuid().v4(),
                      mediaHouseId: _selectedMHId!,
                      mediaHouseName: _selectedMHName!,
                      agencyName: _agencyCtrl.text.trim(),
                      isActive: true,
                      createdAt: DateTime.now(),
                    );
                    await ref.read(agencyMappingProvider.notifier).create(mapping);
                    setModalState(() { _adding = false; _selectedMHId = null; _agencyCtrl.clear(); });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: _adding
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Mapping'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MappingTile extends ConsumerWidget {
  final AgencyMappingModel mapping;
  const _MappingTile({required this.mapping});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderDark)),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mapping.mediaHouseName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(child: Text(mapping.agencyName, style: const TextStyle(color: AppColors.accent, fontSize: 13))),
              ]),
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await ConfirmDialog.show(context, title: 'Delete Mapping', message: 'Remove mapping: ${mapping.mediaHouseName} → ${mapping.agencyName}?', confirmLabel: 'Delete', isDanger: true);
                if (ok) ref.read(agencyMappingProvider.notifier).delete(mapping.id);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), title: Text('Remove', style: TextStyle(color: AppColors.error)), dense: true, contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
    );
  }
}
