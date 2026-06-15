import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/route_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/auth_provider.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/party/party_list_screen.dart';
import 'presentation/screens/party/party_form_screen.dart';
import 'presentation/screens/media_house/media_house_screen.dart';
import 'presentation/screens/agency/agency_mapping_screen.dart';
import 'presentation/screens/release_order/ro_screen.dart';
import 'presentation/screens/publication/publication_tracker_screen.dart';
import 'presentation/screens/invoice/invoice_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/document_vault/document_vault_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/navigation/main_navigation.dart';

class SaishyMediaErpApp extends ConsumerWidget {
  const SaishyMediaErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _buildRouter(ref);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SAISHY Media ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: RouteConstants.splash,
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);
        final isLoggedIn = authState.valueOrNull?.isLoggedIn ?? false;
        final isOnAuthPage = state.matchedLocation == RouteConstants.login ||
            state.matchedLocation == RouteConstants.splash;

        if (!isLoggedIn && !isOnAuthPage) return RouteConstants.login;
        if (isLoggedIn && state.matchedLocation == RouteConstants.login) {
          return RouteConstants.dashboard;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: RouteConstants.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: RouteConstants.login,
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainNavigation(child: child),
          routes: [
            GoRoute(
              path: RouteConstants.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: RouteConstants.parties,
              builder: (context, state) => const PartyListScreen(),
            ),
            GoRoute(
              path: RouteConstants.partyForm,
              builder: (context, state) => PartyFormScreen(
                partyId: state.uri.queryParameters['id'],
              ),
            ),
            GoRoute(
              path: RouteConstants.mediaHouses,
              builder: (context, state) => const MediaHouseListScreen(),
            ),
            GoRoute(
              path: RouteConstants.mediaHouseForm,
              builder: (context, state) => MediaHouseFormScreen(
                mediaHouseId: state.uri.queryParameters['id'],
              ),
            ),
            GoRoute(
              path: RouteConstants.agencyMapping,
              builder: (context, state) => const AgencyMappingScreen(),
            ),
            GoRoute(
              path: RouteConstants.releaseOrders,
              builder: (context, state) => const RoListScreen(),
            ),
            GoRoute(
              path: RouteConstants.releaseOrderForm,
              builder: (context, state) => RoFormScreen(
                roNumber: state.uri.queryParameters['ro'],
              ),
            ),
            GoRoute(
              path: RouteConstants.releaseOrderDetail,
              builder: (context, state) => RoDetailScreen(
                roNumber: state.pathParameters['roNumber'] ?? '',
              ),
            ),
            GoRoute(
              path: RouteConstants.publicationTracker,
              builder: (context, state) => const PublicationTrackerScreen(),
            ),
            GoRoute(
              path: RouteConstants.billingQueue,
              builder: (context, state) => const BillingQueueScreen(),
            ),
            GoRoute(
              path: RouteConstants.invoices,
              builder: (context, state) => const InvoiceListScreen(),
            ),
            GoRoute(
              path: RouteConstants.invoiceForm,
              builder: (context, state) => InvoiceFormScreen(
                invoiceNumber: state.uri.queryParameters['inv'],
                roNumber: state.uri.queryParameters['ro'],
              ),
            ),
            GoRoute(
              path: RouteConstants.invoiceDetail,
              builder: (context, state) => InvoiceDetailScreen(
                invoiceNumber: state.pathParameters['invoiceNumber'] ?? '',
              ),
            ),
            GoRoute(
              path: RouteConstants.payments,
              builder: (context, state) => const PaymentListScreen(),
            ),
            GoRoute(
              path: RouteConstants.paymentForm,
              builder: (context, state) => PaymentFormScreen(
                invoiceNumber: state.uri.queryParameters['inv'],
              ),
            ),
            GoRoute(
              path: RouteConstants.reports,
              builder: (context, state) => const ReportsScreen(),
            ),
            GoRoute(
              path: RouteConstants.documentVault,
              builder: (context, state) => const DocumentVaultScreen(),
            ),
            GoRoute(
              path: RouteConstants.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.error}'),
        ),
      ),
    );
  }
}

// Theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
