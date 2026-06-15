import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/route_constants.dart';
import '../data/providers/auth_provider.dart';
import '../presentation/navigation/main_navigation.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/party/party_list_screen.dart';
import '../presentation/screens/party/party_form_screen.dart';
import '../presentation/screens/media_house/media_house_screen.dart';
import '../presentation/screens/media_house/rate_card_screen.dart';
import '../presentation/screens/release_order/ro_screen.dart';
import '../presentation/screens/publication/publication_tracker_screen.dart';
import '../presentation/screens/invoice/invoice_screen.dart';
import '../presentation/screens/reports/reports_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../data/models/party_model.dart';
import '../data/models/media_house_model.dart';
import '../data/models/media_rate_card_model.dart';
import '../data/models/release_order_model.dart';
import '../data/models/invoice_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/screens/agency/agency_mapping_screen.dart';
import '../presentation/screens/document_vault/document_vault_screen.dart';

// Placeholder screens for modules not yet fully implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text('$title — Coming Soon', style: const TextStyle(color: Colors.white))),
  );
}

// ── Router Configuration ───────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuth = authAsync.valueOrNull?.isLoggedIn ?? false;
      final isAuthRoute = state.matchedLocation == RouteConstants.login;
      final isSplash = state.matchedLocation == RouteConstants.splash;
      if (isSplash) return null;
      if (!isAuth && !isAuthRoute) return RouteConstants.login;
      if (isAuth  &&  isAuthRoute) return RouteConstants.dashboard;
      return null;
    },
    routes: [
      // Splash
      GoRoute(path: RouteConstants.splash, builder: (_, __) => const SplashScreen()),

      // Auth
      GoRoute(path: RouteConstants.login, builder: (_, __) => const LoginScreen()),

      // Shell (bottom nav)
      ShellRoute(
        builder: (ctx, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(path: RouteConstants.dashboard, builder: (_, __) => const DashboardScreen()),
          GoRoute(path: RouteConstants.roList, builder: (_, __) => const ReleaseOrderListScreen()),
          GoRoute(path: RouteConstants.publicationTracker, builder: (_, __) => const PublicationTrackerScreen()),
          GoRoute(path: RouteConstants.invoiceList, builder: (_, __) => const InvoiceListScreen()),
        ],
      ),

      // Clients
      GoRoute(path: RouteConstants.partyList, builder: (_, __) => const PartyListScreen()),
      GoRoute(path: RouteConstants.partyCreate, builder: (_, __) => const PartyFormScreen()),
      GoRoute(path: RouteConstants.partyEdit,
        builder: (_, state) => PartyFormScreen(party: state.extra as PartyModel?)),

      // Media Houses
      GoRoute(path: RouteConstants.mediaHouseList, builder: (_, __) => const MediaHouseListScreen()),
      GoRoute(path: RouteConstants.mediaHouseCreate, builder: (_, __) => const MediaHouseFormScreen()),
      GoRoute(path: RouteConstants.mediaHouseEdit,
        builder: (_, state) => MediaHouseFormScreen(mediaHouse: state.extra as MediaHouseModel?)),

      // Rate Cards
      GoRoute(path: RouteConstants.rateCards,
        builder: (_, state) => RateCardScreen(mediaHouse: state.extra as MediaHouseModel)),

      // Agency Mappings
      GoRoute(path: RouteConstants.agencyMappings,
        builder: (_, __) => const AgencyMappingScreen()),

      // Release Orders
      GoRoute(path: RouteConstants.roCreate, builder: (_, __) => const ReleaseOrderFormScreen()),
      GoRoute(path: RouteConstants.roEdit,
        builder: (_, state) => ReleaseOrderFormScreen(ro: state.extra as ReleaseOrderModel?)),
      GoRoute(path: RouteConstants.roDetail,
        builder: (_, state) {
          final ro = state.extra as ReleaseOrderModel;
          return _RODetailWrapper(ro: ro);
        }),

      // Payments
      GoRoute(path: RouteConstants.paymentList,
        builder: (_, __) => const _PlaceholderScreen(title: 'All Payments')),
      GoRoute(path: RouteConstants.paymentCreate,
        builder: (_, state) => PaymentFormScreen(invoice: state.extra as InvoiceModel)),

      // Invoice detail
      GoRoute(path: RouteConstants.invoiceDetail,
        builder: (_, state) => InvoiceDetailScreen(invoice: state.extra as InvoiceModel)),

      // Reports
      GoRoute(path: RouteConstants.reports, builder: (_, __) => const ReportsScreen()),

      // Document Vault
      GoRoute(path: RouteConstants.documentVault,
        builder: (_, __) => const DocumentVaultScreen()),

      // Settings
      GoRoute(path: RouteConstants.settings, builder: (_, __) => const SettingsScreen()),
    ],
  );
});

// RO Detail View
class _RODetailWrapper extends StatelessWidget {
  final ReleaseOrderModel ro;
  const _RODetailWrapper({required this.ro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: Text(ro.roNumber),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push(RouteConstants.roEdit, extra: ro)),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _detail('Client', ro.partyName, Icons.people_outline_rounded),
        _detail('Media House', ro.mediaHouseName, Icons.newspaper_outlined),
        _detail('Agency', ro.agencyName, Icons.swap_horiz_rounded),
        _detail('Publication Date', ro.publicationDate.toString().split('T').first, Icons.calendar_today_rounded),
        _detail('Category', ro.category, Icons.category_outlined),
        _detail('Ad Size', '${ro.adWidth} × ${ro.adHeight} ${ro.adUnit}', Icons.aspect_ratio_rounded),
        _detail('Rate', '₹${ro.rate} / ${ro.adUnit}', Icons.price_change_outlined),
        _detail('Net Payable', '₹${ro.netPayable.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined),
        _detail('Status', ro.status, Icons.info_outline_rounded),
        if (ro.notes != null) _detail('Notes', ro.notes!, Icons.notes_rounded),
      ]),
    );
  }

  Widget _detail(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1A1D27), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2D3A))),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12))),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
