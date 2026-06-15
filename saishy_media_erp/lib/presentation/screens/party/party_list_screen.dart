import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/party_model.dart';
import '../../../data/providers/party_provider.dart';
import '../../widgets/common_widgets.dart';

class PartyListScreen extends ConsumerStatefulWidget {
  const PartyListScreen({super.key});
  @override
  ConsumerState<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends ConsumerState<PartyListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partyProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.read(partyProvider.notifier).refresh()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search clients...',
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
            child: partiesAsync.when(
              loading: () => const LoadingWidget(message: 'Loading clients...'),
              error: (e, _) => EmptyStateWidget(title: 'Error loading clients', subtitle: e.toString(), icon: Icons.error_outline_rounded),
              data: (parties) {
                final filtered = _search.isEmpty ? parties : parties.where((p) =>
                  p.name.toLowerCase().contains(_search.toLowerCase()) ||
                  p.mobile.contains(_search) ||
                  (p.contactPerson?.toLowerCase().contains(_search.toLowerCase()) ?? false)).toList();
                if (filtered.isEmpty) return EmptyStateWidget(
                  title: _search.isEmpty ? 'No Clients Found' : 'No results for "$_search"',
                  subtitle: _search.isEmpty ? 'Add your first client using the + button' : null,
                  icon: Icons.people_outline_rounded,
                  actionLabel: _search.isEmpty ? 'Add Client' : null,
                  onAction: _search.isEmpty ? () => context.push(RouteConstants.partyCreate) : null,
                );
                return RefreshIndicator(
                  onRefresh: () => ref.read(partyProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _PartyTile(party: filtered[i])
                        .animate().fadeIn(delay: Duration(milliseconds: i * 40), duration: 300.ms),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.partyCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Client'),
      ),
    );
  }
}

class _PartyTile extends ConsumerWidget {
  final PartyModel party;
  const _PartyTile({required this.party});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        title: Text(party.name,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(party.mobile, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              if (party.contactPerson != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(child: Text(party.contactPerson!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ]),
            if (party.gstApplicable) ...[
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Text('GST', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                if (party.gstin != null) ...[
                  const SizedBox(width: 6),
                  Text(party.gstin!, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ]),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          color: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (action) async {
            if (action == 'edit') {
              context.push(RouteConstants.partyEdit, extra: party);
            } else if (action == 'delete') {
              final ok = await ConfirmDialog.show(context,
                title: 'Delete Client', message: 'Delete ${party.name}? This cannot be undone.',
                confirmLabel: 'Delete', isDanger: true);
              if (ok) await ref.read(partyProvider.notifier).delete(party.id);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined, size: 18), title: Text('Edit'), dense: true, contentPadding: EdgeInsets.zero)),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), title: Text('Delete', style: TextStyle(color: AppColors.error)), dense: true, contentPadding: EdgeInsets.zero)),
          ],
        ),
        onTap: () => context.push(RouteConstants.partyEdit, extra: party),
      ),
    );
  }
}
