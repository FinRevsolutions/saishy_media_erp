import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/route_constants.dart';
import '../core/theme/app_colors.dart';
import '../data/providers/connectivity_provider.dart' show connectivityProvider;
import '../data/providers/dashboard_provider.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final Widget child;
  const MainNavigation({super.key, required this.child});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  static const _destinations = [
    _NavItem(icon: Icons.dashboard_outlined,      activeIcon: Icons.dashboard_rounded,     label: 'Dashboard',  route: RouteConstants.dashboard),
    _NavItem(icon: Icons.article_outlined,        activeIcon: Icons.article_rounded,       label: 'ROs',        route: RouteConstants.roList),
    _NavItem(icon: Icons.track_changes_outlined,  activeIcon: Icons.track_changes_rounded, label: 'Tracker',    route: RouteConstants.publicationTracker),
    _NavItem(icon: Icons.receipt_long_outlined,   activeIcon: Icons.receipt_long_rounded,  label: 'Invoices',   route: RouteConstants.invoiceList),
    _NavItem(icon: Icons.menu_rounded,            activeIcon: Icons.menu_rounded,          label: 'More',       route: ''),
  ];

  void _onTap(int index) {
    if (index == 4) {
      _showMoreDrawer();
      return;
    }
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    context.go(_destinations[index].route);
  }

  void _showMoreDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider);

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              color: AppColors.warning.withOpacity(0.9),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Offline Mode — Showing cached data',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTap,
        backgroundColor: AppColors.navBarDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon, size: 22),
                  selectedIcon: Icon(d.activeIcon, size: 22, color: AppColors.primary),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.route});
}

class _MoreSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _SheetItem(Icons.people_outline_rounded,      'Clients',           RouteConstants.partyList),
      _SheetItem(Icons.newspaper_outlined,          'Media Houses',      RouteConstants.mediaHouseList),
      _SheetItem(Icons.swap_horiz_rounded,          'Agency Mappings',   RouteConstants.agencyMappings),
      _SheetItem(Icons.price_change_outlined,       'Rate Cards',        RouteConstants.rateCards),
      _SheetItem(Icons.account_balance_wallet_outlined, 'Payments',      RouteConstants.paymentList),
      _SheetItem(Icons.bar_chart_rounded,           'Reports',           RouteConstants.reports),
      _SheetItem(Icons.folder_outlined,             'Document Vault',    RouteConstants.documentVault),
      _SheetItem(Icons.settings_outlined,           'Settings',          RouteConstants.settings),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('More', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: items.map((item) => _SheetGridItem(item: item)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetItem {
  final IconData icon;
  final String label;
  final String route;
  const _SheetItem(this.icon, this.label, this.route);
}

class _SheetGridItem extends StatelessWidget {
  final _SheetItem item;
  const _SheetGridItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.push(item.route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.2),
          ),
        ],
      ),
    );
  }
}
