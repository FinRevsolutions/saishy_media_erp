import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/connectivity_provider.dart' show connectivityProvider;
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final stats   = ref.watch(dashboardProvider);
    final user    = ref.watch(currentUserProvider);
    final isOnline = ref.watch(connectivityProvider);
    final hour    = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.surfaceDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.15), AppColors.surfaceDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$greeting,', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text(user?.fullName ?? 'User',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(user?.role.label ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (!isOnline)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: const Row(children: [
                              Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 12),
                              SizedBox(width: 4),
                              Text('Offline', style: TextStyle(color: AppColors.warning, fontSize: 10)),
                            ]),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.sync_rounded),
                          tooltip: 'Sync',
                          onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────
          stats.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('Could not load dashboard.\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (s) => SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildStatsGrid(s).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),
                _buildRevenueCard(s).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                const SizedBox(height: 24),
                _buildRecentROs(s).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                const SizedBox(height: 24),
                _buildStatusChart(s).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.roCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New RO'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats s) {
    final items = [
      _StatData('Total Clients',        s.totalClients.toString(),          Icons.people_rounded,                    AppColors.primary),
      _StatData('Media Houses',         s.totalMediaHouses.toString(),       Icons.newspaper_rounded,                 AppColors.accent),
      _StatData('Total ROs',            s.totalROs.toString(),               Icons.article_rounded,                   AppColors.info),
      _StatData('This Month ROs',       s.monthlyROs.toString(),             Icons.calendar_today_rounded,            AppColors.success),
      _StatData('Pending Pubs',         s.pendingPublications.toString(),    Icons.pending_actions_rounded,           AppColors.warning),
      _StatData('Pending Bills',        s.pendingBills.toString(),           Icons.receipt_long_rounded,              AppColors.error),
      _StatData('Outstanding',          AppFormatters.currency(s.outstandingAmount), Icons.account_balance_wallet_rounded, AppColors.error),
      _StatData('Monthly Revenue',      AppFormatters.currency(s.monthlyRevenue),   Icons.trending_up_rounded,           AppColors.success),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.7,
        ),
        itemBuilder: (_, i) => StatCard(
          title: items[i].title,
          value: items[i].value,
          icon: items[i].icon,
          color: items[i].color,
        ),
      ),
    );
  }

  Widget _buildRevenueCard(DashboardStats s) {
    if (s.chartData.isEmpty) return const SizedBox.shrink();

    final maxRevenue = s.chartData
        .map((d) => double.tryParse(d['revenue']?.toString() ?? '0') ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Revenue (6 Months)',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                AppFormatters.currency(s.totalRevenue),
                style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: s.chartData.map((d) {
                final rev = double.tryParse(d['revenue']?.toString() ?? '0') ?? 0;
                final pct = maxRevenue > 0 ? (rev / maxRevenue) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (pct * 80).clamp(4, 80),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(d['month']?.toString() ?? '',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentROs(DashboardStats s) {
    if (s.recentROs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Recent Release Orders',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(RouteConstants.roList),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...s.recentROs.map((ro) => _RecentROTile(ro: ro)),
      ],
    );
  }

  Widget _buildStatusChart(DashboardStats s) {
    if (s.statusDistribution.isEmpty) return const SizedBox.shrink();
    final total = s.statusDistribution.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    const colors = {
      'Draft': AppColors.textMuted,
      'Sent': AppColors.info,
      'Accepted': AppColors.primary,
      'Published': AppColors.success,
      'Billed': AppColors.warning,
      'Paid': AppColors.accent,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.donut_large_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('RO Status Distribution',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          ...s.statusDistribution.entries.map((e) {
            final pct = e.value / total;
            final color = colors[e.key] ?? AppColors.textMuted;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(e.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct, minHeight: 8,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatData {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatData(this.title, this.value, this.icon, this.color);
}

class _RecentROTile extends StatelessWidget {
  final Map<String, dynamic> ro;
  const _RecentROTile({required this.ro});

  @override
  Widget build(BuildContext context) {
    final status = ro['status']?.toString() ?? '';
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.article_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ro['ro_number']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${ro['party_name']} • ${ro['media_house_name']}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Draft':     return AppColors.textMuted;
      case 'Sent':      return AppColors.info;
      case 'Accepted':  return AppColors.primary;
      case 'Published': return AppColors.success;
      case 'Billed':    return AppColors.warning;
      case 'Paid':      return AppColors.accent;
      default:          return AppColors.textMuted;
    }
  }
}
