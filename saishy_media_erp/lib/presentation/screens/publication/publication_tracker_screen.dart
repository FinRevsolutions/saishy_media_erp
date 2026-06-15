import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/release_order_model.dart';
import '../../../data/models/publication_model.dart';
import '../../../data/providers/release_order_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class PublicationTrackerScreen extends ConsumerStatefulWidget {
  const PublicationTrackerScreen({super.key});
  @override
  ConsumerState<PublicationTrackerScreen> createState() => _PublicationTrackerState();
}

class _PublicationTrackerState extends ConsumerState<PublicationTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pubsAsync = ref.watch(publicationProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Publication Tracker'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.read(publicationProvider.notifier).refresh()),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'), Tab(text: 'Pending'), Tab(text: 'Published'), Tab(text: 'Billed'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Search publications...', prefixIcon: Icon(Icons.search_rounded, size: 20), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: pubsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading publications...'),
              error: (e, _) => EmptyStateWidget(title: 'Error', subtitle: e.toString(), icon: Icons.error_outline_rounded),
              data: (pubs) {
                final filtered = _search.isEmpty ? pubs : pubs.where((p) =>
                  p.roNumber.toLowerCase().contains(_search.toLowerCase()) ||
                  p.partyName.toLowerCase().contains(_search.toLowerCase()) ||
                  p.mediaHouseName.toLowerCase().contains(_search.toLowerCase())).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _PubList(pubs: filtered),
                    _PubList(pubs: filtered.where((p) => p.status != 'Published' && p.status != 'Billed' && p.status != 'Paid').toList()),
                    _PubList(pubs: filtered.where((p) => p.status == 'Published').toList()),
                    _PubList(pubs: filtered.where((p) => p.status == 'Billed' || p.status == 'Paid').toList()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PubList extends ConsumerWidget {
  final List<PublicationModel> pubs;
  const _PubList({required this.pubs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pubs.isEmpty) return const EmptyStateWidget(
      title: 'No Publications', subtitle: 'No publications in this category',
      icon: Icons.track_changes_outlined,
    );
    return RefreshIndicator(
      onRefresh: () => ref.read(publicationProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: pubs.length,
        itemBuilder: (_, i) => _PubCard(pub: pubs[i])
            .animate().fadeIn(delay: Duration(milliseconds: i * 40), duration: 300.ms),
      ),
    );
  }
}

class _PubCard extends ConsumerWidget {
  final PublicationModel pub;
  const _PubCard({required this.pub});

  static const _statusOrder = ['Draft', 'Sent', 'Accepted', 'Published', 'Billed', 'Paid'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubDate = DateFormat('dd MMM yyyy').format(pub.publicationDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderDark)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(pub.roNumber, style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700))),
                  StatusChip(label: pub.status),
                ]),
                const SizedBox(height: 6),
                Text('${pub.partyName} • ${pub.mediaHouseName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Publication: $pubDate', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  if (pub.publishedEdition != null && pub.publishedEdition!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.newspaper_rounded, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(pub.publishedEdition!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ]),
                // Status pipeline
                const SizedBox(height: 12),
                _StatusPipeline(current: pub.status),
              ],
            ),
          ),
          // Action buttons
          if (pub.status != 'Paid')
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderDark))),
              child: Row(
                children: _buildActions(context, ref, pub),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref, PublicationModel pub) {
    final nextIdx = _statusOrder.indexOf(pub.status) + 1;
    if (nextIdx >= _statusOrder.length) return [];

    final nextStatus = _statusOrder[nextIdx];
    final actions = <Widget>[];

    actions.add(Expanded(
      child: TextButton.icon(
        onPressed: () => _updateStatus(context, ref, pub, nextStatus),
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: Text('Mark as $nextStatus', style: const TextStyle(fontSize: 12)),
      ),
    ));

    if (pub.cuttingUrl == null) {
      actions.add(const VerticalDivider(color: AppColors.borderDark, width: 1, indent: 8, endIndent: 8));
      actions.add(Expanded(
        child: TextButton.icon(
          onPressed: () => _uploadCutting(context, ref, pub),
          icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.accent),
          label: const Text('Upload Cutting', style: TextStyle(fontSize: 12, color: AppColors.accent)),
        ),
      ));
    } else {
      actions.add(const VerticalDivider(color: AppColors.borderDark, width: 1, indent: 8, endIndent: 8));
      actions.add(Expanded(
        child: TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.success),
          label: const Text('View Cutting', style: TextStyle(fontSize: 12, color: AppColors.success)),
        ),
      ));
    }

    return actions;
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, PublicationModel pub, String newStatus) async {
    final user   = ref.read(currentUserProvider);
    final updated = pub.copyWith(
      status: newStatus,
      statusUpdatedAt: DateTime.now(),
      statusUpdatedBy: user?.fullName ?? 'Unknown',
    );
    final ok = await ref.read(publicationProvider.notifier).updateStatus(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Status updated to $newStatus' : 'Failed to update status'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _uploadCutting(BuildContext context, WidgetRef ref, PublicationModel pub) async {
    // Navigate to document upload for this publication
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Camera upload: Open from document vault'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _StatusPipeline extends StatelessWidget {
  final String current;
  const _StatusPipeline({required this.current});

  static const _stages = ['Draft', 'Sent', 'Accepted', 'Published', 'Billed', 'Paid'];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _stages.indexOf(current);
    return Row(
      children: List.generate(_stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stageIdx = i ~/ 2;
          final done = stageIdx < currentIdx;
          return Expanded(child: Container(height: 2, color: done ? AppColors.primary : AppColors.borderDark));
        }
        final stageIdx = i ~/ 2;
        final done = stageIdx <= currentIdx;
        final isCurrent = stageIdx == currentIdx;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCurrent ? 16 : 12, height: isCurrent ? 16 : 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primary : AppColors.borderDark,
                border: isCurrent ? Border.all(color: AppColors.primary, width: 2) : null,
              ),
              child: isCurrent ? const Icon(Icons.circle, color: Colors.white, size: 8) : null,
            ),
            const SizedBox(height: 2),
            Text(_stages[stageIdx], style: TextStyle(
              color: isCurrent ? AppColors.primary : (done ? AppColors.textSecondary : AppColors.textMuted),
              fontSize: 8, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            )),
          ],
        );
      }),
    );
  }
}
