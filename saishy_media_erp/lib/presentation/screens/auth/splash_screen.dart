import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 600));

    _setStatus('Loading local database...');
    await LocalDbService.instance.initialize();

    _setStatus('Checking connectivity...');
    await ConnectivityService.instance.initialize();

    _setStatus('Initializing API...');
    await ApiService().initialize();

    _setStatus('Syncing data...');
    if (ConnectivityService.instance.isOnline) {
      SyncService.instance.syncAll();
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Check auth state
    final auth = await ref.read(authStateProvider.future);
    if (auth.isLoggedIn) {
      context.go(RouteConstants.dashboard);
    } else {
      context.go(RouteConstants.login);
    }
  }

  void _setStatus(String status) {
    if (mounted) setState(() => _status = status);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.loginGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 56),
              )
                  .animate(controller: _ctrl)
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 28),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'Media Agency Management System',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
              const SizedBox(height: 60),
              // Loading indicator
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
